require "spec_helper"

RSpec.describe "POST /auth/register" do
  it "returns 201 when valid" do
    post "/auth/register", { email: "x@y.com", username: "user", password: "123456" }.to_json, { "CONTENT_TYPE" => "application/json" }
    expect(last_response.status).to eq(201)
  end

  it "returns 422 when fields are missing" do
    post "/auth/register", { email: "x@y.com" }.to_json, { "CONTENT_TYPE" => "application/json" }
    expect(last_response.status).to eq(422)
  end
end
