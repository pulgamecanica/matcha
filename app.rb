require_relative './config/environment'

class MatchaApp < Sinatra::Base
  configure do
    enable :sessions
    set :show_exceptions, false
  end

  use AuthController
  use UsersController
  use TagsController
  use BlockedUsersController
  use LikesController
  use ProfileViewsController
  use PicturesController
  use LocationController
  
  get '/' do
    { status: "Matcha API v4.2" }.to_json
  end
end
