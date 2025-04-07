require_relative '../helpers/database'
require 'bcrypt'

class User
  include BCrypt

  def self.db
    @db ||= ::Database.connection
  end

  def self.create(params)
    params = params.transform_keys(&:to_s)
    password_digest = Password.create(params['password'])

    db.exec_params(
      <<~SQL,
        INSERT INTO users (
          username, email, password_digest,
          first_name, last_name,
          gender, sexual_preferences
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id
      SQL
      [
        params['username'],
        params['email'],
        password_digest,
        params['first_name'],
        params['last_name'],
        params['gender'],
        params['sexual_preferences']
      ]
    )
  end

  def self.find_by_username(username)
    res = db.exec_params("SELECT * FROM users WHERE username = $1", [username])
    res.first
  end

  def self.find_by_id(id)
    res = db.exec_params("SELECT * FROM users WHERE id = $1", [id])
    res.first
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
    db.exec_params(
      "INSERT INTO user_social_logins (user_id, provider, provider_user_id, created_at)
       VALUES ($1, $2, $3, NOW())",
      [user_id, provider, provider_user_id]
    )
  end

  def self.verify_credentials(username, password)
    user = find_by_username(username)
    return nil unless user

    digest = Password.new(user["password_digest"])
    digest == password ? user : nil
  end

  def self.confirm!(username)
    db.exec_params(
      "UPDATE users SET is_email_verified = TRUE WHERE username = $1",
      [username]
    )
  end

  def self.delete(id)
    db.exec_params("DELETE FROM users WHERE id = $1", [id])
  end

end
