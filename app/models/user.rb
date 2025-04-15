# frozen_string_literal: true

require 'bcrypt'

require_relative '../helpers/database'
require_relative '../helpers/sql_helper'
require_relative '../helpers/request_helper'
require_relative '../lib/geolocation'

class User
  include BCrypt

  def self.all(serialize_public_user: true)
    Database.pool.with do |conn|
      res = conn.exec('SELECT * FROM users ORDER BY username ASC')
      res.map { |user| serialize_public_user ? UserSerializer.public_view(user) : user }
    end
  end

  def self.create(params)
    params = RequestHelper.normalize_params(params)
    params['password_digest'] = Password.create(params.delete('password'))
    params['fame_rating'] = 1.0

    allowed_fields = %w[
      username email password_digest first_name
      last_name gender sexual_preferences birth_year
      fame_rating
    ]

    SQLHelper.create(:users, params, allowed_fields)
  end

  def self.update(user_id, fields)
    allowed_fields = %w[
      username first_name last_name biography
      gender sexual_preferences birth_year
      latitude longitude profile_picture_id
    ]

    SQLHelper.update(:users, user_id, fields, allowed_fields)
  end

  def self.find_by_username(username)
    SQLHelper.find_by(:users, :username, username)
  end

  def self.find_by_id(id)
    SQLHelper.find_by_id(:users, id)
  end

  def self.find_by_social_login(provider, provider_user_id)
    Database.pool.with do |conn|
      sql = <<~SQL
        SELECT users.* FROM users
        JOIN user_social_logins usl ON usl.user_id = users.id
        WHERE usl.provider = $1 AND usl.provider_user_id = $2
      SQL
      res = conn.exec_params(sql, [provider, provider_user_id])
      res&.first
    end
  end

  def self.link_social_login(user_id, provider, provider_user_id)
    SQLHelper.create(
      :user_social_logins,
      {
        user_id: user_id,
        provider: provider,
        provider_user_id: provider_user_id,
        created_at: Time.now
      },
      %w[user_id provider provider_user_id created_at]
    )
  end

  def self.verify_credentials(username, password)
    user = find_by_username(username)
    return nil unless user

    digest = Password.new(user['password_digest'])
    digest == password ? user : nil
  end

  def self.confirm!(username)
    SQLHelper.update_column(:users, :is_email_verified, true, { username: username })
  end

  def self.ban!(username)
    result = SQLHelper.update_column(:users, :is_banned, true, { username: username })
    result.cmd_tuples.positive?
  end

  def self.delete(id)
    result = SQLHelper.delete(:users, id)
    result.cmd_tuples.positive?
  end

  def self.tags(user_id)
    SQLHelper.many_to_many(:user, :tags, user_id)
  end

  def self.likes(user_id)
    ids = Like.liked_user_ids(user_id)
    res = SQLHelper.find_many_by_ids(:users, ids)
    res.map { |user| UserSerializer.public_view(user) }
  end

  def self.liked_by(user_id)
    ids = Like.liked_by_user_ids(user_id)
    res = SQLHelper.find_many_by_ids(:users, ids)
    res.map { |user| UserSerializer.public_view(user) }
  end

  def self.matches(user_id)
    Like.matches(user_id)
  end

  def self.blocked_users(user_id)
    BlockedUser.blocked_users_for(user_id)
  end

  def self.blocked_by(user_id)
    BlockedUser.blocked_by(user_id)
  end

  def self.visitors_for(user_id)
    ProfileView.visited(user_id)
  end

  def self.views(user_id)
    ProfileView.views(user_id)
  end

  def self.pictures(user_id)
    Picture.for_user(user_id)
  end

  def self.locations(user_id)
    LocationHistory.for_user(user_id)
  end

  def self.location(user_id)
    user = find_by_id(user_id)
    {
      latitude: user['latitude'],
      longitude: user['longitude']
    }
  end

  def self.connections(user_id)
    Connection.all_for_user(user_id)
  end

  def self.connected_with?(user_a_id, user_b_id)
    !!Connection.find_between(user_a_id, user_b_id)
  end

  def self.messages(user_id)
    connections = User.connections(user_id)

    connections.map do |user|
      conn = Connection.find_between(user_id, user['id'])
      next unless conn

      {
        user: UserSerializer.public_view(user),
        messages: Message.for_connection(conn['id'])
      }
    end.compact
  end

  def self.dates(user_id)
    Date.all_for_user(user_id)
  end

  def self.notifications(user_id)
    Notification.for_user(user_id)
  end

  def self.age(user)
    return nil unless user['birth_year']

    Time.now.year - user['birth_year'].to_i
  end

  ############################
  # DISCOVER ALGORITHM
  ############################

  def self.discover(current, filters = {})
    return [] unless current

    candidates = discover_candidates(current)
    candidates = filter_by_preferences(current, candidates)
    candidates = filter_out_connections(current, candidates)
    candidates = filter_by_fame_and_age(candidates, filters)

    candidates.map! do |u|
      distance_score = location_score(current, u, filters['location'])
      tag_score = tag_score(u, filters['tags'])
      fame_score = fame_rating_score(u['fame_rating'])
      {
        user: UserSerializer.public_view(u),
        score: { location_score: distance_score, tag_score: tag_score, fame_score: fame_score,
                 total: ((distance_score + tag_score + fame_score) / 3.0).round(2) }
      }
    end
    candidates.sort_by { |x| -x[:score][:total] }
  end

  def self.discover_candidates(current)
    all(serialize_public_user: false).reject do |u|
      u['id'].to_i == current['id'].to_i || u['is_banned'] == 't'
    end
  end

  def self.filter_by_preferences(current, candidates)
    candidates.select { |u| matches_preferences?(current, u) && matches_preferences?(u, current) }
  end

  def self.filter_out_connections(current, candidates)
    connections_ids = connections(current['id']).map { |u| u['id'] }
    candidates.reject { |u| connections_ids.include?(u['id']) }
  end

  def self.filter_by_fame_and_age(candidates, filters)
    candidates.select do |u|
      fame_ok = filters['min_fame'].nil? || u['fame_rating'].to_f >= filters['min_fame'].to_f
      age_ok = age_filter_passes?(u, filters)
      fame_ok && age_ok
    end
  end

  def self.age_filter_passes?(user, filters)
    return true unless filters['min_age'] || filters['max_age']

    return false unless user['birth_year']

    age = Time.now.year - user['birth_year'].to_i
    (filters['min_age'].nil? || age >= filters['min_age'].to_i) &&
      (filters['max_age'].nil? || age <= filters['max_age'].to_i)
  end

  def self.location_score(current, other, location_filter)
    return 100.0 unless location_filter

    user_loc = location_filter || { latitude: current['latitude'], longitude: current['longitude'] }
    other_loc = {
      latitude: other['latitude']&.to_f,
      longitude: other['longitude']&.to_f
    }

    return 0 unless other_loc[:latitude] && other_loc[:longitude]

    distance = Geolocation.haversine_distance(
      user_loc['latitude'].to_f,
      user_loc['longitude'].to_f,
      other_loc[:latitude],
      other_loc[:longitude]
    )

    return 0 unless distance

    max = location_filter['max_distance_km']&.to_f || 1000.0
    normalized = [1 - [distance / max, 1.0].min, 0].max

    (normalized * 100).round(2)
  end

  def self.tag_score(candidate, filter_tags)
    return 100.0 if filter_tags.nil? || filter_tags.empty?

    user_tags = tags(candidate['id']).map { |t| t['name'] }

    shared = (user_tags & filter_tags).size
    total = filter_tags.size
    ((shared.to_f / total) * 100).round(2)
  end

  def self.fame_rating_score(fame)
    [(fame.to_f / 100) * 100, 100].min.round(2)
  end

  def self.matches_preferences?(user, other)
    case user['sexual_preferences']
    when 'everyone'
      true
    when 'non_binary'
      other['gender'] == 'other'
    else
      user['sexual_preferences'] == other['gender']
    end
  end
end
