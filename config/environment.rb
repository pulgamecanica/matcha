require "sinatra/base"
require "pg"
require "dotenv/load"
require "json"
require "sinatra/reloader"

require_relative "../app/doc/api_doc"
Dir["./app/controllers/*.rb"].each { |f| require f }
Dir["./app/models/*.rb"].each { |f| require f }
Dir["./app/helpers/*.rb"].each { |f| require f }

