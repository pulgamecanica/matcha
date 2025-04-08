require_relative '../helpers/database'
require_relative '../helpers/sql_helper'

class Picture
  def self.db
    @db ||= Database.connection
  end

  def self.create(user_id, url, is_profile: false)
    SQLHelper.create(:pictures, {
      user_id: user_id,
      url: url,
      is_profile: is_profile,
      created_at: Time.now,
      updated_at: Time.now
    }, %w[user_id url is_profile created_at updated_at])
  end

  def self.for_user(user_id)
    db.exec_params("SELECT * FROM pictures WHERE user_id = $1 ORDER BY created_at ASC", [user_id]).to_a
  end

  def self.find_by_id(id)
    SQLHelper.find_by_id(:pictures, id)
  end

  def self.update(id, fields)
    SQLHelper.update(:pictures, id, fields, %w[url is_profile])
  end

  def self.delete(id)
    SQLHelper.delete(:pictures, id)
  end

  def self.unset_profile(user_id)
    db.exec_params("UPDATE pictures SET is_profile = FALSE WHERE user_id = $1", [user_id])
  end

  def self.set_profile(user_id, picture_id)
    unset_profile(user_id)
    db.exec_params("UPDATE pictures SET is_profile = TRUE WHERE id = $1 AND user_id = $2", [picture_id, user_id])
    find_by_id(picture_id)
  end
end
