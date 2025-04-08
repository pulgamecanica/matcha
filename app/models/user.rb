require 'bcrypt'

require_relative '../helpers/database'
require_relative '../helpers/sql_helper'
require_relative '../helpers/request_helper'

class User
  include BCrypt

  def self.db
    @db ||= ::Database.connection
  end

  def self.all
    res = db.exec("SELECT * FROM users ORDER BY username ASC")
    res.to_a
  end

  def self.create(params)
    params = RequestHelper.normalize_params(params)
    params['password_digest'] = Password.create(params.delete('password'))

    allowed_fields = %w[
      username email password_digest first_name
      last_name gender sexual_preferences
    ]

    SQLHelper.create(:users, params, allowed_fields)
  end

  def self.update(user_id, fields)
    allowed_fields = %w[
      username first_name last_name biography
      gender sexual_preferences latitude longitude
      profile_picture_id
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
    sql = <<~SQL
      SELECT users.* FROM users
      JOIN user_social_logins usl ON usl.user_id = users.id
      WHERE usl.provider = $1 AND usl.provider_user_id = $2
    SQL
    res = db.exec_params(sql, [provider, provider_user_id])
    res.first
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

    digest = Password.new(user["password_digest"])
    digest == password ? user : nil
  end

  def self.confirm!(username)
    SQLHelper.update_column(:users, :is_email_verified, true, { username: username })
  end

  def self.ban!(username)
    result = SQLHelper.update_column(:users, :is_banned, true, { username: username })
    result.cmd_tuples > 0
  end

  def self.delete(id)
    result = SQLHelper.delete(:users, id)
    result.cmd_tuples > 0
  end

  def self.tags(user_id)
    SQLHelper.many_to_many(:user, :tags, user_id)
  end

  def self.likes(user_id)
    ids = Like.liked_user_ids(user_id)
    SQLHelper.find_many_by_ids(:users, ids)
  end

  def self.liked_by(user_id)
    ids = Like.liked_by_user_ids(user_id) 
    SQLHelper.find_many_by_ids(:users, ids)    
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

  def self.viewed_by(user_id)
    ProfileView.viewed_by(user_id)
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
      latitude: user["latitude"],
      longitude: user["longitude"]
    }
  end

end
