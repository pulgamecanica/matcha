require 'pg'
require 'uri'

module Database
  def self.connection
    uri = URI.parse(ENV['DATABASE_URL'])
    PG.connect(
      host: uri.host,
      user: uri.user,
      password: uri.password,
      dbname: uri.path[1..-1]
    )
  end
end
