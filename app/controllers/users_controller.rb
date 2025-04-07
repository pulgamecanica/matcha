require_relative './base_controller'

class UsersController < BaseController

  # ---------------------------
  # ME
  # ---------------------------
  api_doc "/me", method: :get do
    description "Get the currently authenticated user"
    response 200, "User object"
    response 401, "Missing or invalid token"
    response 403, "User not confirmed or banned"
  end

  get "/me" do
    require_auth!

    user_data = @current_user.reject { |k, _| k == "password_digest" }
    user_data.to_json
  end
end