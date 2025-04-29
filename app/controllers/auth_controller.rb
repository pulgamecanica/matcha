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
    tags 'Auth'
    description 'Register a new user'
    param :username, String, required: true, desc: 'Unique username (max 20 characters)'
    param :email, String, required: true, desc: 'User email address used for login and verification'
    param :password, String, required: true, desc: 'User password (will be securely hashed)'
    param :first_name, String, required: true, desc: "User's first name"
    param :last_name, String, required: true, desc: "User's last name"
    response 201, 'User created', example: { message: 'User created!' }
    response 422, 'Validation error', example: {
      error: 'Validation failed',
      details: {
        username: ['is required'],
        email: ['is invalid']
      }
    }
    response 422, 'Username or email taken', example: {
      error: 'Username or email already taken'
    }
    @data[:auth_required] = false
  end

  post '/auth/register' do
    data = json_body

    begin
      UserValidator.validate!(data)
      user = User.create(data)
      action = EmailAction.create(user['id'], 'email_confirmation')
      Mailer.send_confirmation_email(user['email'], action['code'])
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
    tags 'Auth'
    description 'Authenticate an existing user using username and password'
    param :username, String, required: true, desc: "User's unique username"
    param :password, String, required: true, desc: "User's account password"
    response 200, 'Login successful', example: { token: 'jwt.token.here' }
    response 401, 'Invalid credentials', example: { error: 'Invalid credentials' }
    response 403, 'Email not confirmed', example: { error: 'Please confirm your email first.' }
    response 403, 'User banned', example: { error: 'User is banned.' }
    @data[:auth_required] = false
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
    tags 'Auth'
    description 'Authenticate or register a user via social login (OAuth provider)'
    param :provider, String, required: true, desc: "OAuth provider (e.g., 'google', 'github', 'intra')"
    param :provider_user_id, String, required: true, desc: 'Unique ID returned by the provider for this user'
    param :first_name, String, required: false, desc: "User's first name (optional if new user)"
    param :last_name, String, required: false, desc: "User's last name (optional if new user)"
    param :picture_url, String, required: false, desc: "User's picture"
    response 200, 'User authenticated', example: { token: 'jwt.token.here' }
    response 201, 'User created via social login', example: { token: 'jwt.token.here' }
    response 422, 'Missing required social login fields', example: { error: 'Missing provider or UID' }
    @data[:auth_required] = false
  end

  post '/auth/social' do
    data = json_body
    provider = data['provider']
    uid = data['provider_user_id']

    halt 422, { error: 'Missing provider or UID' }.to_json unless provider && uid

    user = User.find_by_social_login(provider, uid)

    unless user
      user = User.create({
                           username: "#{provider}_#{uid}".slice(0, 20),
                           email: "#{uid.slice(0, 9)}@#{provider}.matcha",
                           password: SecureRandom.hex(16), # Not used, just for DB consistency
                           first_name: data['first_name'].slice(0, 20) || '',
                           last_name: data['last_name'].slice(0, 20) || '',
                           sexual_preferences: 'everyone',
                           is_email_verified: true
                         })
      User.link_social_login(user['id'], provider, uid)
      User.confirm!(user['username'])

      if data['picture_url']
        pic = Picture.create(user['id'], data['picture_url'], is_profile: true)
        Picture.set_profile(user['id'], pic['id'])
      end
    end

    token = SessionToken.generate(user['id'])
    { token: token }.to_json
  end
end
