ENV["APP_ENV"] = "test"

require "rack/test"
require "rspec"
require_relative "../app"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    MatchaApp
  end
end
