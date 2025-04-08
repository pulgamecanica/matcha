class BlockedUser
  def self.db
    @db ||= Database.connection
  end

  def self.block!(blocker_id, blocked_id)
    raise Errors::ValidationError.new("You cannot block yourself") if blocker_id == blocked_id

    db.exec_params(
      "INSERT INTO blocked_users (blocker_id, blocked_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [blocker_id, blocked_id]
    )
  end

  def self.unblock!(blocker_id, blocked_id)
    db.exec_params(
      "DELETE FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2",
      [blocker_id, blocked_id]
    )
  end

  def self.blocked_users_for(user_id)
    res = db.exec_params(<<~SQL, [user_id])
      SELECT users.* FROM users
      JOIN blocked_users ON users.id = blocked_users.blocked_id
      WHERE blocked_users.blocker_id = $1
    SQL
    res.to_a
  end

  def self.blocked_by(user_id)
    res = db.exec_params(<<~SQL, [user_id])
      SELECT users.* FROM users
      JOIN blocked_users ON users.id = blocked_users.blocker_id
      WHERE blocked_users.blocked_id = $1
    SQL
    res.to_a
  end

  def self.blocked?(blocker_id, blocked_id)
    res = db.exec_params(
      "SELECT 1 FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2 LIMIT 1",
      [blocker_id, blocked_id]
    )
    !res.to_a.empty?
  end
end
