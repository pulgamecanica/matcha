# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative './errors'

module Geolocation
  API_URL = 'http://ip-api.com/json/'

  def self.lookup(ip)
    uri = URI("#{API_URL}#{ip}?fields=status,message,country,city,lat,lon")
    response = Net::HTTP.get_response(uri)

    raise Errors::ValidationError, 'Geolocation service failed' unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)

    unless data['status'] == 'success'
      raise Errors::ValidationError, "Geolocation failed: #{data['message'] || 'unknown error'}"
    end

    {
      country: data['country'],
      city: data['city'],
      latitude: data['lat'],
      longitude: data['lon']
    }
  rescue StandardError => e
    raise Errors::ValidationError, "Failed to geolocate IP: #{e.message}"
  end
end
