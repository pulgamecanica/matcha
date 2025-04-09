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

  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
            'Access-Control-Allow-Headers' => 'Authorization, Content-Type'
  end

  # Preflight route for CORS
  options "*" do
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
    200
  end

  get '/' do
    { message: "Welcome to MatchaApp" }.to_json
  end
end
