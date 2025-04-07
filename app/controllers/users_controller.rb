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
    response 200, "Profile updated & user object"
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

  # ---------------------------
  # LOOKUP USERNAME
  # ---------------------------
  api_doc "/users/:username", method: :get do
    description "Fetch the public profile of a user by their username"
    param :username, String, required: true, desc: "The unique username of the user"
    response 200, "Public user data"
    response 404, "User not found or banned"
  end

  get "/users/:username" do
    user = User.find_by_username(params[:username])
    halt 404, { error: "User not found" }.to_json unless user
    halt 404, { error: "User not available" }.to_json if user["is_banned"] == "t"
    {
      username: user["username"],
      first_name: user["first_name"],
      last_name: user["last_name"],
      biography: user["biography"],
      gender: user["gender"],
      sexual_preferences: user["sexual_preferences"],
      profile_picture_id: user["profile_picture_id"],
      online_status: user["online_status"] == "t",
      last_seen_at: user["last_seen_at"]
    }.to_json
  end

  # ---------------------------
  # DELETE USERNAME
  # ---------------------------
  api_doc "/me", method: :delete do
    description "Delete the current authenticated user account and all related data"
    response 204, "User deleted"
    response 401, "Unauthorized - missing or invalid token"
  end

  delete "/me" do
    halt 401, { error: "Unauthorized" }.to_json unless @current_user
    User.delete(@current_user["id"])
    status 204
  end
end