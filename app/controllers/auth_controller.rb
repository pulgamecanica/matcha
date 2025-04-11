# frozen_string_literal: true

require 'sinatra/base'
require 'securerandom'
require_relative '../models/user'
require_relative '../helpers/user_validator'
require_relative '../helpers/auth'
require_relative '../helpers/session_token'
require_relative './base_controller'

class AuthController < BaseController
  # ---------------------------
  # REGISTER
  # ---------------------------
  api_doc '/auth/register', method: :post do
    description 'Register a new user'

    param :username, String, required: true, desc: 'Unique username (max 20 characters)'
    param :email, String, required: true, desc: 'User email address used for login and verification'
    param :password, String, required: true, desc: 'User password (will be securely hashed)'
    param :first_name, String, required: true, desc: "User's first name"
    param :last_name, String, required: true, desc: "User's last name"

    response 201, 'User created'
    response 422, 'Validation error (missing fields, invalid values, or already taken)'
  end

  post '/auth/register' do
    data = json_body

    begin
      UserValidator.validate!(data)
      User.create(data)
      status 201
      { message: 'User created!' }.to_json
    rescue Errors::ValidationError => e
      halt 422, { error: e.message, details: e.details }.to_json
    rescue PG::UniqueViolation
      halt 422, { error: 'Username or email already taken' }.to_json
    end
  end

  # ---------------------------
  # LOGIN
  # ---------------------------
  api_doc '/auth/login', method: :post do
    description 'Authenticate an existing user using username and password'

    param :username, String, required: true, desc: "User's unique username"
    param :password, String, required: true, desc: "User's account password"

    response 200, 'Login successful, session token returned'
    response 401, 'Invalid credentials'
    response 403, 'Email not confirmed or user is banned'
  end

  post '/auth/login' do
    data = json_body
    user = User.verify_credentials(data['username'], data['password'])

    if user.nil?
      halt 401, { error: 'Invalid credentials' }.to_json
    elsif user['is_email_verified'] != 't'
      halt 403, { error: 'Please confirm your email first.' }.to_json
    elsif user['is_banned'] == 't'
      halt 403, { error: 'User is banned.' }.to_json
    end

    token = SessionToken.generate(user['id'])
    { token: token }.to_json
  end

  # ---------------------------
  # SOCIAL LOGIN
  # ---------------------------
  api_doc '/auth/social', method: :post do
    description 'Authenticate or register a user via social login (OAuth provider)'

    param :provider, String, required: true, desc: "OAuth provider (e.g., 'google', 'github', 'intra')"
    param :provider_user_id, String, required: true, desc: 'Unique ID returned by the provider for this user'
    param :first_name, String, required: false, desc: "User's first name (optional if new user)"
    param :last_name, String, required: false, desc: "User's last name (optional if new user)"

    response 200, 'User authenticated successfully'
    response 201, 'User created via social login'
    response 422, 'Missing required social login fields'
  end

  post '/auth/social' do
    data = json_body
    provider = data['provider']
    uid = data['provider_user_id']

    halt 422, { error: 'Missing provider or UID' }.to_json unless provider && uid

    user = User.find_by_social_login(provider, uid)

    unless user
      user = User.create({
                           username: "#{provider}_#{uid}",
                           email: "#{uid}@#{provider}.matcha",
                           password: SecureRandom.hex(16), # Not used, just for DB consistency
                           first_name: data['first_name'] || '',
                           last_name: data['last_name'] || '',
                           gender: 'other',
                           sexual_preferences: 'both',
                           is_email_verified: true
                         })
      User.link_social_login(user['id'], provider, uid)
    end

    token = SessionToken.generate(user['id'])
    { token: token }.to_json
  end

  # ---------------------------
  # EMAIL CONFIRMATION
  # ---------------------------
  api_doc '/auth/confirm', method: :post do
    description 'Confirm a user manually (simulated email confirmation)'

    param :username, String, required: true, desc: 'Username of the user to confirm'

    response 200, 'User confirmed'
    response 404, 'User not found'
  end

  post '/auth/confirm' do
    data = json_body
    user = User.find_by_username(data['username'])
    halt 404, { error: 'User not found' }.to_json unless user

    User.confirm!(data['username'])
    { message: 'User confirmed!' }.to_json
  end
end
