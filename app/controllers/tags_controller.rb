require_relative './base_controller'
require_relative '../models/tag'
require_relative '../models/user_tag'
require_relative '../helpers/tag_validator'

class TagsController < BaseController
  before do
    require_auth!
  end

  # ---------------------------
  # TAGS
  # ---------------------------
  api_doc "/tags", method: :get do
    description "List all tags"
    response 200, "Returns a list of available tags"
  end
  get "/tags" do
    { data: Tag.all }.to_json
  end

  # ---------------------------
  # NEW TAG
  # ---------------------------
  api_doc "/tags", method: :post do
    description "Create a new tag"
    param :name, String, required: true, desc: "The name of the tag"
    response 201, "Tag created"
    response 422, "Missing or invalid name"
    response 422, "Tag name already taken"
  end
  post "/tags" do
    data = json_body

    begin
      TagValidator.validate_name!(data["name"])
      tag = Tag.create(data["name"])
      status 201
      { message: "Tag created", data: tag }.to_json
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    rescue PG::UniqueViolation
      halt 422, { error: "Tag name already taken" }.to_json
    end
  end

  # ---------------------------
  # USER TAGS
  # ---------------------------
  api_doc "/me/tags", method: :get do
    description "List all tags for the current user"
    response 200, "Returns user’s tags"
    response 401, "Unauthorized"
  end
  get "/me/tags" do
    { data: User.tags(@current_user["id"]) }.to_json
  end

  # ---------------------------
  # NEW USER TAG
  # ---------------------------
  api_doc "/me/tags", method: :post do
    description "Add a tag to the current user"
    param :name, String, required: true, desc: "The name of the tag to add, if tag doesn't exist it's created"
    response 200, "Tag added to user"
    response 422, "Tag name missing or invalid"
  end
  post "/me/tags" do
    data = json_body
    halt 422, { error: "Missing tag name" }.to_json unless data["name"]

    tag = Tag.find_by_name(data["name"]) || Tag.create(data["name"])
    UserTag.add_tag(@current_user["id"], tag["id"])
    { message: "Tag added", data: tag }.to_json
  end

  # ---------------------------
  # DELETE USER TAG
  # ---------------------------
  api_doc "/me/tags", method: :delete do
    description "Remove a tag from the current user"
    param :name, String, required: true, desc: "The name of the tag to remove"
    response 200, "Tag removed"
    response 422, "Missing or invalid tag"
  end
  delete "/me/tags" do
    data = json_body
    halt 422, { error: "Missing tag name" }.to_json unless data["name"]

    tag = Tag.find_by_name(data["name"])
    halt 422, { error: "Tag not found" }.to_json unless tag

    UserTag.remove_tag(@current_user["id"], tag["id"])
    { message: "Tag removed" }.to_json
  end
end
