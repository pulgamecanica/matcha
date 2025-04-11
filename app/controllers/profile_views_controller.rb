# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/user'

class ProfileViewsController < BaseController
  # ---------------------------
  # WHO VISITED ME
  # ---------------------------
  api_doc '/me/visits', method: :get do
    description 'See who has viewed your profile'
    response 200, 'List of users who viewed you'
  end
  get '/me/visits' do
    visitors = User.visitors_for(@current_user['id'])
    { data: visitors }.to_json
  end

  # ---------------------------
  # WHO I VISITED
  # ---------------------------
  api_doc '/me/viewed_by', method: :get do
    description 'See which users you have viewed'
    response 200, 'List of profiles you viewed'
  end
  get '/me/viewed_by' do
    visited = User.viewed_by(@current_user['id'])
    { data: visited }.to_json
  end
end
