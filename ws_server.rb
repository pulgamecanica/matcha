# frozen_string_literal: true

require_relative './app/helpers/session_token'
require_relative './app/models/user'
require 'faye/websocket'
require 'json'
require 'concurrent'

class WebSocketServer < Sinatra::Base
  puts '🔧 WebSocketServer mounted at /ws'

  KEEPALIVE_TIME = 30 # in seconds
  CHANNELS = Concurrent::Map.new

  get '/' do
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env, nil, ping: KEEPALIVE_TIME)
      user = nil

      ws.on :open do |_event|
        user = extract_current_user(env)
        if user
          CHANNELS[user['id']] = ws
          User.set_online!(user['id'])
          puts "🔌 WebSocket connected: user #{user['username']}"
        else
          ws.close(4001, 'Unauthorized')
        end
      end

      ws.on :message do |event|
        puts "📩 From #{user['id']}: #{event.data}"
        # You can echo back or forward to other users
      end

      ws.on :close do |_event|
        if user
          CHANNELS.delete(user['id'])
          User.set_offline!(user['id'])
          puts "❌ Disconnected: user #{user['username']}"
        end
        ws = nil
      end

      ws.rack_response
    else
      [400, { 'Content-Type' => 'text/plain' }, ['WebSocket only']]
    end
  end

  private

  def extract_current_user(env)
    return nil unless env

    req = Rack::Request.new(env)
    token = env['HTTP_TOKEN'] || req.params['token'] if req
    return nil unless token

    payload = SessionToken.decode(token)
    return nil unless payload

    User.find_by_id(payload['user_id'])
  end
end
