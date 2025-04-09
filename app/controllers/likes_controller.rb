require_relative './base_controller'
require_relative '../models/like'
require_relative '../models/user'
require_relative '../helpers/like_validator'

class LikesController < BaseController
  # ---------------------------
  # NEW LIKE
  # ---------------------------
  api_doc "/me/like", method: :post do
    description "Like another user"
    param :username, String, required: true, desc: "The username of the user to like"
    response 200, "User liked"
    response 404, "User not found or unavailable"
    response 422, "Invalid request"
  end

  post "/me/like" do
    data = json_body

    begin
      LikeValidator.validate!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    target = User.find_by_username(data["username"])
    halt 404, { error: "User not found" }.to_json unless target
    halt 404, { error: "User not available" }.to_json if target["is_banned"] == "t"
    halt 422, { error: "You cannot like yourself" }.to_json if target["id"] == @current_user["id"]
    
    Like.like!(@current_user["id"], target["id"])
    { message: "You liked #{data["username"]}" }.to_json
  end

  # ---------------------------
  # DELETE LIKE
  # ---------------------------
  api_doc "/me/like", method: :delete do
    description "Unlike a user"
    param :username, String, required: true, desc: "The username of the user to unlike"
    response 200, "User unliked"
    response 404, "User not found"
    response 422, "Like does not exist"
  end

  delete "/me/like" do
    data = json_body

    begin
      LikeValidator.validate!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    target = User.find_by_username(data["username"])
    halt 404, { error: "User not found" }.to_json unless target

    unless Like.exists?(@current_user["id"], target["id"])
      halt 422, { error: "You haven't liked this user yet" }.to_json
    end

    Like.unlike!(@current_user["id"], target["id"])
    { message: "#{data["username"]} has been unliked" }.to_json
  end


  # ---------------------------
  # USER LIKES
  # ---------------------------
  api_doc "/me/likes", method: :get do
    description "Get list of users you have liked"
    response 200, "Array of liked user objects"
  end

  get "/me/likes" do
    { data: User.likes(@current_user["id"]) }.to_json
  end

  # ---------------------------
  # USER LIKES
  # ---------------------------
  api_doc "/me/liked_by", method: :get do
    description "Get list of users you have liked"
    response 200, "Array of liked user objects"
  end

  get "/me/liked_by" do
    { data: User.liked_by(@current_user["id"]) }.to_json
  end

  # ---------------------------
  # USER MATCHES
  # ---------------------------
  api_doc "/me/matches", method: :get do
    description "Get list of users who liked you back (matches)"
    response 200, "Array of matched user objects"
  end

  get "/me/matches" do
    matches = Like.matches(@current_user["id"])
    { data: matches }.to_json
  end
end
