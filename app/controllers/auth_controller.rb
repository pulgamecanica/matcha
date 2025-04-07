require "sinatra/base"
include APIDoc
  
class AuthController < Sinatra::Base
  api_doc "/auth/register", method: :post do
    description "Register a new user"
    param :email, String, required: true, desc: "User email to confirm the account"
    param :username, String, required: true
    param :password, String, required: true
    response 201, "User created"
    response 422, "Validation error"
  end

  post "/auth/register" do
    body = JSON.parse(request.body.read)
    halt 422, { error: "Missing fields" }.to_json unless body["email"] && body["username"] && body["password"]

    status 201
    { message: "User registered (mock)" }.to_json
  end
end
