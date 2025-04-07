require "spec_helper"

describe "GET /me" do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  let(:user_data) do
    {
      username: "authme",
      email: "authme@example.com",
      password: "supersecret",
      first_name: "Authy",
      last_name: "Tester",
      gender: "other",
      sexual_preferences: "everyone"
    }
  end

  before do
    User.create(user_data)
    User.confirm!(user_data[:username])
    @user = User.find_by_username(user_data[:username])
    @token = SessionToken.generate(@user["id"])
  end

  it "returns the current authenticated user" do
    get "/me", nil, headers.merge("HTTP_AUTHORIZATION" => "Bearer #{@token}")

    expect(last_response.status).to eq(200)
    json = JSON.parse(last_response.body)
    expect(json["username"]).to eq("authme")
    expect(json).not_to have_key("password_digest")
  end

  it "returns 401 if token is missing" do
    get "/me", nil, headers

    expect(last_response.status).to eq(401)
    expect(JSON.parse(last_response.body)["error"]).to match(/missing/i)
  end

  it "returns 401 if token is invalid" do
    get "/me", nil, headers.merge("HTTP_AUTHORIZATION" => "Bearer invalid.token")

    expect(last_response.status).to eq(401)
    expect(JSON.parse(last_response.body)["error"]).to match(/invalid/i)
  end

  it "returns 403 if user is banned" do
    User.ban!(user_data[:username])
    get "/me", nil, headers.merge("HTTP_AUTHORIZATION" => "Bearer #{@token}")

    expect(last_response.status).to eq(403)
    expect(JSON.parse(last_response.body)["error"]).to match(/banned/i)
  end

  it "returns 403 if user is not confirmed" do
    unconfirmed_data = user_data.merge(username: "nope", email: "nope@example.com", is_email_verified: false)
    User.create(unconfirmed_data)
    user = User.find_by_username("nope")
    token = SessionToken.generate(user["id"])

    get "/me", nil, headers.merge("HTTP_AUTHORIZATION" => "Bearer #{token}")

    expect(last_response.status).to eq(403)
    expect(JSON.parse(last_response.body)["error"]).to match(/email not verified/i)
  end
end
