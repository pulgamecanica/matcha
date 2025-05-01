# frozen_string_literal: true

require 'logger'
require_relative './config/environment'
require_relative './app/lib/cors'
require_relative './app/lib/logger'

class MatchaApp < Sinatra::Base
  configure do
    set :protection, false
    use Rack::Protection, permitted_origins: ['http://localhost:5173', 'http://127.0.0.1:5173', 'https://matcha42.fly.dev']
    set :allow_hosts, ['matcha42.fly.dev']
    set :host_authorization, {
      permitted_hosts: []
    }
  end

  use CORS

  get '/' do
    { message: 'Welcome to MatchaApp' }.to_json
  end

  use AuthController
  use EmailActionsController
  use UsersController
  use TagsController
  use BlockedUsersController
  use LikesController
  use ProfileViewsController
  use PicturesController
  use LocationController
  use ConnectionsController
  use MessagesController
  use DatesController
  use NotificationsController
  use ReportsController
end

at_exit do
  puts 'Shutting down DB connections...'
  Database.pool.shutdown do |conn|
    conn.close
  rescue StandardError
    nil
  end
end
