# frozen_string_literal: true

require 'pg'
require 'uri'
require 'connection_pool'

module Database
  def self.pool
    @pool ||= ConnectionPool.new(size: 5, timeout: 5) do
      uri = URI.parse(ENV['DATABASE_URL'])
      PG.connect(
        host: uri.host,
        user: uri.user,
        password: uri.password,
        dbname: uri.path[1..]
      )
    end
  end

  def self.with_open_conn(&block)
    pool ||= ConnectionPool.new(size: 5, timeout: 5) do
      uri = URI.parse(ENV['DATABASE_URL'])
      PG.connect(
        host: uri.host,
        user: uri.user,
        password: uri.password,
        dbname: uri.path[1..]
      )
    end
    pool.with(&block)
  end
end
