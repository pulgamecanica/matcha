require 'bcrypt'

require_relative '../helpers/database'
require_relative '../helpers/sql_helper'

class User
  include BCrypt

  def self.db
    @db ||= ::Database.connection
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

end
