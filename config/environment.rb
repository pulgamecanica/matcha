require "sinatra/base"
require "pg"
require "dotenv/load"
require "json"

require_relative "../app/doc/api_doc"
require_relative "../app/helpers/validator"
Dir["./app/controllers/*.rb"].each { |f| require f }

