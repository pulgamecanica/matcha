require_relative '../helpers/database'
require_relative './user'
require_relative './tag'

class UserTag
  def self.db
    @db ||= ::Database.connection
  end

  def self.add_tag(user_id, tag_id)
    db.exec_params(
      "INSERT INTO user_tags (user_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [user_id, tag_id]
    )
  end

  def self.remove_tag(user_id, tag_id)
    db.exec_params(
      "DELETE FROM user_tags WHERE user_id = $1 AND tag_id = $2",
      [user_id, tag_id]
    )
  end

  def self.user(user_id, tag_id)
    res = db.exec_params(
      "SELECT users.* FROM users
       JOIN user_tags ut ON ut.user_id = users.id
       WHERE ut.user_id = $1 AND ut.tag_id = $2",
      [user_id, tag_id]
    )
    res.first
  end

  def self.tag(user_id, tag_id)
    res = db.exec_params(
      "SELECT tags.* FROM tags
       JOIN user_tags ut ON ut.tag_id = tags.id
       WHERE ut.user_id = $1 AND ut.tag_id = $2",
      [user_id, tag_id]
    )
    res.first
  end
end
