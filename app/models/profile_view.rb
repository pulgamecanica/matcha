require_relative '../helpers/database'

class ProfileView
  def self.db
    @db ||= ::Database.connection
  end

  def self.record(viewer_id, viewed_id)
    return if viewer_id == viewed_id

    db.exec_params(<<~SQL, [viewer_id, viewed_id])
      INSERT INTO profile_views (viewer_id, viewed_id, visited_at)
      VALUES ($1, $2, NOW())
    SQL
  end

  def self.visited(user_id)
    db.exec_params(<<~SQL, [user_id]).to_a
      SELECT users.*, profile_views.visited_at FROM users
      JOIN profile_views ON profile_views.viewed_id = users.id
      WHERE profile_views.viewer_id = $1
      ORDER BY profile_views.visited_at DESC
    SQL
  end

  def self.viewed_by(user_id)
    db.exec_params(<<~SQL, [user_id]).to_a
      SELECT users.*, profile_views.visited_at FROM users
      JOIN profile_views ON profile_views.viewer_id = users.id
      WHERE profile_views.viewed_id = $1
      ORDER BY profile_views.visited_at DESC
    SQL
  end
end
