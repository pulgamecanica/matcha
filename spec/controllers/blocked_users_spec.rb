require "spec_helper"

describe "User blocking behavior" do

  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  def create_and_authenticate!(data)
    User.create(data)
    User.confirm!(data[:username])
    user = User.find_by_username(data[:username])
    SessionToken.generate(user["id"])
  end

  def auth_headers(token)
    headers.merge("HTTP_AUTHORIZATION" => "Bearer #{token}")
  end

  let(:alice) { { username: "alice", email: "alice@example.com", password: "pass", first_name: "A", last_name: "A", gender: "female", sexual_preferences: "male" } }
  let(:bob)   { { username: "bob",   email: "bob@example.com",   password: "pass", first_name: "B", last_name: "B", gender: "male", sexual_preferences: "female" } }
  let(:carol) { { username: "carol", email: "carol@example.com", password: "pass", first_name: "C", last_name: "C", gender: "female", sexual_preferences: "everyone" } }

  let(:alice_token) { create_and_authenticate(alice) }
  let(:bob_token)   { create_and_authenticate(bob) }
  let(:carol_token) { create_and_authenticate(carol) }

  before do
    @alice_token = create_and_authenticate!(alice)
    @bob_token = create_and_authenticate!(bob)
    @carol_token = create_and_authenticate!(carol)

    # alice blocks bob
    blocker = User.find_by_username("alice")
    blocked = User.find_by_username("bob")
    BlockedUser.block!(blocker["id"], blocked["id"])

    # carol blocks alice
    carol_user = User.find_by_username("carol")
    alice_user = User.find_by_username("alice")
    BlockedUser.block!(carol_user["id"], alice_user["id"])
  end

  it "prevents bob from accessing alice's profile" do
    get "/users/alice", nil, auth_headers(@bob_token)
    expect(last_response.status).to eq(404)
  end

  it "prevents alice from accessing carol's profile" do
    get "/users/carol", nil, auth_headers(@alice_token)
    expect(last_response.status).to eq(404)
  end

  it "allows carol to view bob" do
    get "/users/bob", nil, auth_headers(@carol_token)
    expect(last_response.status).to eq(200)
  end

  it "lists users I blocked" do
    get "/me/blocked", nil, auth_headers(@alice_token)
    expect(last_response.status).to eq(200)
    list = JSON.parse(last_response.body)["data"]
    expect(list.map { |u| u["username"] }).to include("bob")
  end

  it "lists users who blocked me" do
    get "/me/blocked_by", nil, auth_headers(@alice_token)
    expect(last_response.status).to eq(200)
    list = JSON.parse(last_response.body)["data"]
    expect(list.map { |u| u["username"] }).to include("carol")
  end
end