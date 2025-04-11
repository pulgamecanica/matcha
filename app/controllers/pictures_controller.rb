# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/picture'
require_relative '../models/user'
require_relative '../helpers/picture_validator'

class PicturesController < BaseController
  # ---------------------------
  # USER PICTURES
  # ---------------------------
  api_doc '/me/pictures', method: :get do
    description 'List all pictures uploaded by the current user'
    response 200, 'Returns list of pictures'
  end
  get '/me/pictures' do
    pictures = User.pictures(@current_user['id'])
    { data: pictures }.to_json
  end

  # ---------------------------
  # ADD NEW PICTURE
  # ---------------------------
  api_doc '/me/pictures', method: :post do
    description 'Upload a new picture'
    param :url, String, required: true, desc: 'URL of the picture'
    param :is_profile, TrueClass, required: false, desc: 'Set as profile picture'
    response 201, 'Picture created'
    response 422, 'Invalid data'
  end
  post '/me/pictures' do
    data = json_body

    begin
      PictureValidator.validate_create!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    picture = Picture.create(@current_user['id'], data['url'], is_profile: data['is_profile'])

    User.update(@current_user['id'], { profile_picture_id: picture['id'] }) if data['is_profile']

    status 201
    { message: 'Picture uploaded!', data: picture }.to_json
  end

  # ---------------------------
  # UPDATE PICTURE
  # ---------------------------
  api_doc '/me/pictures/:id', method: :patch do
    description 'Edit a picture (e.g., set as profile)'
    param :id, Integer, required: true
    param :is_profile, TrueClass, required: false
    param :url, String, required: false
    response 200, 'Picture updated'
    response 404, 'Picture not found'
    response 403, 'Not your picture'
  end
  patch '/me/pictures/:id' do
    picture = Picture.find_by_id(params[:id])
    halt 404, { error: 'Picture not found' }.to_json unless picture
    halt 403, { error: 'Unauthorized' }.to_json if picture['user_id'] != @current_user['id']

    data = json_body

    begin
      PictureValidator.validate_update!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    updates = data.slice('url', 'is_profile')

    picture = Picture.update(picture['id'], updates)

    if updates['is_profile']
      Picture.set_profile(@current_user['id'], picture['id'])
      User.update(@current_user['id'], { profile_picture_id: picture['id'] })
    end
    { message: 'Picture updated!', data: picture }.to_json
  end

  # ---------------------------
  # DELETE PICTURE
  # ---------------------------
  api_doc '/me/pictures/:id', method: :delete do
    description 'Delete a picture'
    param :id, Integer, required: true
    response 200, 'Picture deleted'
    response 404, 'Not found'
    response 403, 'Unauthorized'
  end
  delete '/me/pictures/:id' do
    picture = Picture.find_by_id(params[:id])
    halt 404, { error: 'Picture not found' }.to_json unless picture
    halt 403, { error: 'Unauthorized' }.to_json if picture['user_id'] != @current_user['id']

    Picture.delete(picture['id'])

    # Unset profile picture reference if it was removed
    User.update(@current_user['id'], { profile_picture_id: nil }) if @current_user['profile_picture_id'] == picture['id']

    { message: 'Picture deleted' }.to_json
  end
end
