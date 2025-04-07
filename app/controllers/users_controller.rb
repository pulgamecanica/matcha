require_relative './base_controller'

class UsersController < BaseController
  before do
    require_auth!
  end

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

  # ---------------------------
  # EDIT ME
  # ---------------------------
  api_doc "/me", method: :patch do
    description "Update profile fields for the current authenticated user"
    param :username, String, required: false, desc: "New username (must be unique)"
    param :first_name, String, required: false
    param :last_name, String, required: false
    param :gender, String, required: false, desc: "One of: male, female, other"
    param :sexual_preferences, String, required: false, desc: "One of: male, female, non_binary, everyone"
    param :biography, String, required: false
    param :latitude, Float, required: false
    param :longitude, Float, required: false
    response 200, "Profile updated"
    response 401, "Unauthorized"
    response 422, "Validation failed"
  end

  patch "/me" do
    data = json_body

    begin
      UserValidator.validate_update!(data)
      updated_user = User.update(@current_user["id"], data)
      { message: "Profile updated!", user: updated_user.reject { |k, _| k == "password_digest" } }.to_json
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end
  end
end