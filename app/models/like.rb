require_relative '../helpers/database'

class Like
  def self.db
    @db ||= Database.connection
  end

  def self.like!(liker_id, liked_id)
    return if liker_id == liked_id
    db.exec_params(
      "INSERT INTO likes (liker_id, liked_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [liker_id, liked_id]
    )
  end

  def self.unlike!(liker_id, liked_id)
    db.exec_params(
      "DELETE FROM likes WHERE liker_id = $1 AND liked_id = $2",
      [liker_id, liked_id]
    )
  end

  def self.liked_user_ids(user_id)
    res = db.exec_params("SELECT liked_id FROM likes WHERE liker_id = $1", [user_id])
    res.map { |r| r["liked_id"] }
  end

  def self.liked_by_user_ids(user_id)
    res = db.exec_params("SELECT liker_id FROM likes WHERE liked_id = $1", [user_id])
    res.map { |r| r["liker_id"] }
  end

  def self.matches(user_id)
    liked_ids   = Like.liked_user_ids(user_id)
    liker_ids   = Like.liked_by_user_ids(user_id)
    mutual_ids  = liked_ids & liker_ids
    SQLHelper.find_many_by_ids(:users, mutual_ids)
  end

  def self.exists?(liker_id, liked_id)
    sql = <<~SQL
      SELECT 1 FROM likes WHERE liker_id = $1 AND liked_id = $2 LIMIT 1
    SQL
    res = db.exec_params(sql, [liker_id, liked_id])
    !res.ntuples.zero?
  end

end
