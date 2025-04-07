require "sinatra/base"
require_relative "../helpers/request_helper"
require_relative "../lib/errors"

class BaseController < Sinatra::Base
  before do
    content_type :json
  end

  helpers do
    def json_body
      body = request.body.read

      begin
        RequestHelper.safe_json_parse(body)
      rescue Errors::ValidationError => e
        halt 400, { error: e.message }.to_json
      end
    end
  end

  # error Errors::ValidationError do
  #   err = env['sinatra.error']
  #   status 422
  #   { error: err.message, details: err.details }.to_json
  # end

  # error StandardError do
  #   err = env['sinatra.error']
  #   status 500
  #   { error: "Internal Server Error", detail: err.message }.to_json
  # end
end
