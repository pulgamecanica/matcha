require_relative './config/environment'
require_relative './app/lib/cors'

class MatchaApp < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  use CORS

  get '/' do
    { message: "Welcome to MatchaApp" }.to_json
  end

  options '*' do
    200
  end

  use AuthController
  use UsersController
  use TagsController
  use BlockedUsersController
  use LikesController
  use ProfileViewsController
  use PicturesController
  use LocationController
end
