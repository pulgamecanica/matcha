# frozen_string_literal: true

require_relative '../helpers/database'

class ProfileView
  def self.record(viewer_id, viewed_id)
    return if viewer_id == viewed_id

    Database.pool.with do |conn|
      conn.exec_params(<<~SQL, [viewer_id, viewed_id])
        INSERT INTO profile_views (viewer_id, viewed_id, visited_at)
        VALUES ($1, $2, NOW())
      SQL
    end
  end

  def self.visited(user_id)
    Database.pool.with do |conn|
      conn.exec_params(<<~SQL, [user_id]).to_a
        SELECT users.*, profile_views.visited_at FROM users
        JOIN profile_views ON profile_views.viewed_id = users.id
        WHERE profile_views.viewer_id = $1
        ORDER BY profile_views.visited_at DESC
      SQL
    end
  end

  def self.views(user_id)
    Database.pool.with do |conn|
      conn.exec_params(<<~SQL, [user_id]).to_a
        SELECT users.*, profile_views.visited_at FROM users
        JOIN profile_views ON profile_views.viewer_id = users.id
        WHERE profile_views.viewed_id = $1
        ORDER BY profile_views.visited_at DESC
      SQL
    end
  end
end
