# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/user'
require_relative '../models/connection'
require_relative '../helpers/connection_validator'

class ConnectionsController < BaseController
  # ---------------------------
  # LIST CONNECTIONS
  # ---------------------------
  api_doc '/me/connections', method: :get do
    description 'Get all users you are connected with'
    response 200, 'List of connected users'
  end
  get '/me/connections' do
    connections = User.connections(@current_user['id'])
    { data: connections }.to_json
  end

  # ---------------------------
  # CREATE CONNECTION
  # ---------------------------
  api_doc '/me/connect', method: :post do
    description 'Create a connection with a matched user'
    param :username, String, required: true, desc: 'The username of the user to connect with'
    response 200, 'Connection created'
    response 404, 'User not found'
    response 403, 'User is not matched with you'
    response 422, 'Invalid request'
  end
  post '/me/connect' do
    data = json_body

    begin
      ConnectionValidator.validate!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    target = User.find_by_username(data['username'])
    halt 404, { error: 'User not found' }.to_json unless target
    halt 403, { error: 'User is not matched with you' }.to_json unless User.matches(@current_user['id']).any? do |u|
      u['id'] == target['id']
    end

    connection = Connection.create(@current_user['id'], target['id'])
    if connection
      { message: "Connected with #{data['username']}", data: connection }.to_json
    else
      { message: 'Already connected' }.to_json
    end
  end

  # ---------------------------
  # DELETE CONNECTION
  # ---------------------------
  api_doc '/me/connect', method: :delete do
    description 'Remove an existing connection'
    param :username, String, required: true, desc: 'The username of the user to disconnect from'
    response 200, 'Connection removed'
    response 403, 'You and username are not connected'
    response 404, 'User not found'
  end
  delete '/me/connect' do
    data = json_body

    begin
      ConnectionValidator.validate!(data)
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    end

    target = User.find_by_username(data['username'])
    halt 404, { error: 'User not found' }.to_json unless target

    halt 403, { error: "You and #{data['username']} are not connected" }.to_json unless User.connected_with?(
      @current_user['id'], target['id']
    )
    Connection.delete_between(@current_user['id'], target['id'])
    { message: "Disconnected from #{data['username']}" }.to_json
  end
end
