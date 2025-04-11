# frozen_string_literal: true

require_relative './base_controller'
require_relative '../models/location_history'

class LocationController < BaseController
  # ---------------------------
  # GET /me/location
  # ---------------------------
  api_doc '/me/location', method: :get do
    description 'Returns the last known latitude and longitude of the current user'
    response 200, 'Returns current location of the user'
  end
  get '/me/location' do
    { data: User.location(@current_user['id']) }.to_json
  end

  # ---------------------------
  # RECORD LOCATION
  # ---------------------------
  api_doc '/me/location', method: :post do
    description "Record the current user's location (estimated from IP)"
    response 200, 'Location saved'
    response 401, 'Unauthorized'
    response 422, 'Geolocation service failed'
  end
  post '/me/location' do
    ip_address = request.ip
    user_agent = request.user_agent

    begin
      location = Geolocation.lookup(ip_address)
      raise Errors::ValidationError, 'Geolocation service failed' unless location

      record = LocationHistory.record(
        user_id: @current_user['id'],
        latitude: location[:latitude],
        longitude: location[:longitude],
        city: location[:city],
        country: location[:country],
        ip_address: ip_address,
        user_agent: user_agent
      )

      { message: 'Location recorded', data: record }.to_json
    rescue Errors::ValidationError => e
      halt 422, { error: e.message }.to_json
    end
  end

  # ---------------------------
  # USER LOCATIONS
  # ---------------------------
  api_doc '/me/location/history', method: :get do
    description 'Get your full location history'
    response 200, 'List of location records'
    response 401, 'Unauthorized'
  end
  get '/me/location/history' do
    records = User.locations(@current_user['id'])
    { data: records }.to_json
  end
end
