# frozen_string_literal: true

require_relative './app'
require_relative './ws_server'

map '/' do
  run MatchaApp
end

map '/ws' do
  run WebSocketServer
end
