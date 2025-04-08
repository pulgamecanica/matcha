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

  get '/' do
    { status: "Matcha API v4.2" }.to_json
  end
end
