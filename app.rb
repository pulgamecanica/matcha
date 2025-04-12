# frozen_string_literal: true

require_relative './config/environment'
require_relative './app/lib/cors'

class MatchaApp < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  use CORS

  get '/' do
    { message: 'Welcome to MatchaApp' }.to_json
  end

  use AuthController
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
end

at_exit do
  puts 'Shutting down DB connections...'
  Database.pool.shutdown do |conn|
    conn.close
  rescue StandardError
    nil
  end
end
