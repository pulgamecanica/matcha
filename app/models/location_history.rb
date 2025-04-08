require_relative '../helpers/database'
require_relative '../helpers/sql_helper'

class LocationHistory
  def self.db
    @db ||= Database.connection
  end

  def self.record(user_id:, latitude:, longitude:, city: nil, country: nil, ip_address: nil, user_agent: nil)
    location_history = SQLHelper.create(:location_history, {
      user_id: user_id,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      ip_address: ip_address,
      user_agent: user_agent,
      created_at: Time.now
    }, %w[user_id latitude longitude city country ip_address user_agent created_at])
    User.update(user_id, {
      latitude: latitude,
      longitude: longitude
    })
    location_history
  end

  def self.for_user(user_id)
    db.exec_params(<<~SQL, [user_id]).to_a
      SELECT * FROM location_history
      WHERE user_id = $1
      ORDER BY created_at DESC
    SQL
  end
end
