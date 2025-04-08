require_relative './base_controller'
require_relative '../models/blocked_user'
require_relative '../models/user'

class BlockedUsersController < BaseController
  before do
    require_auth!
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
