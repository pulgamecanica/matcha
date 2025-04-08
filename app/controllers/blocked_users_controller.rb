require_relative './base_controller'
require_relative '../models/blocked_user'
require_relative '../models/user'

class BlockedUsersController < BaseController
  before do
    require_auth!
  end

  # ---------------------------
  # BLOCK A USER
  # ---------------------------
  api_doc "/me/block", method: :post do
    description "Block a user by username"
    param :username, String, required: true, desc: "The username of the user to block"
    response 200, "User blocked"
    response 401, "Unauthorized"
    response 404, "User not found"
    response 422, "Cannot block yourself"
  end
  post "/me/block" do
    data = json_body
    halt 422, { error: "Missing username" }.to_json unless data["username"]

    target = User.find_by_username(data["username"])
    halt 404, { error: "User not found" }.to_json unless target

    if target["id"].to_s == @current_user["id"].to_s
      halt 422, { error: "You cannot block yourself" }.to_json
    end

    BlockedUser.block!(@current_user["id"], target["id"])
    { message: "User blocked", data: { username: target["username"] } }.to_json
  end

  # ---------------------------
  # UNBLOCK A USER
  # ---------------------------
  api_doc "/me/block", method: :delete do
    description "Unblock a user by username"
    param :username, String, required: true, desc: "The username of the user to unblock"
    response 200, "User unblocked"
    response 404, "User not found"
  end
  delete "/me/block" do
    data = json_body
    halt 422, { error: "Missing username" }.to_json unless data["username"]

    target = User.find_by_username(data["username"])
    halt 404, { error: "User not found" }.to_json unless target

    BlockedUser.unblock!(@current_user["id"], target["id"])
    { message: "User unblocked", data: { username: target["username"] } }.to_json
  end

  # ---------------------------
  # WHO I BLOCKED
  # ---------------------------
  api_doc "/me/blocked", method: :get do
    description "List users you've blocked"
    response 200, "Returns a list of blocked users"
  end
  get "/me/blocked" do
    blocked = BlockedUser.blocked_users_for(@current_user["id"])
    { data: blocked }.to_json
  end

  # ---------------------------
  # WHO BLOCKED ME
  # ---------------------------
  api_doc "/me/blocked_by", method: :get do
    description "List users who have blocked you"
    response 200, "Returns a list of users who blocked you"
  end
  get "/me/blocked_by" do
    blocked_by = BlockedUser.blocked_by(@current_user["id"])
    { data: blocked_by }.to_json
  end
end
