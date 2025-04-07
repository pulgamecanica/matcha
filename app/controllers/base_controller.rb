require "sinatra/base"
require_relative "../helpers/request_helper"
require_relative "../helpers/session_token"
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

    helpers do
      def require_auth!
        token = request.env["HTTP_AUTHORIZATION"]&.sub(/^Bearer /, "")
        halt 401, { error: 'Missing or invalid Authorization header' }.to_json unless token

        payload = SessionToken.decode(token)
        halt 401, { error: 'Invalid or expired session token' }.to_json unless payload

        user = User.find_by_id(payload["user_id"])
        halt 401, { error: 'Invalid user' }.to_json unless user
        halt 403, { error: 'Email not verified' }.to_json unless user["is_email_verified"] == "t"
        halt 403, { error: 'Account is banned' }.to_json if user["is_banned"] == "t"

        @current_user = user
      end
    end
  end
end
