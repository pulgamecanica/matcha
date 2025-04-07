require 'rake'
require 'pg'
require 'uri'
require 'fileutils'

desc "Export all API docs"
task "doc:export" do
  require_relative "./app/doc/api_doc"
  require_relative "./app"
  
  controllers = ObjectSpace.each_object(Class).select { |cls| cls < Sinatra::Base }
  File.open("docs/exported.md", "w") do |file|
    controllers.each do |ctrl|
      next unless ctrl.respond_to?(:docs)

      ctrl.docs.each do |(method, path), doc|
        file.puts "## #{method} #{path}"
        file.puts "**Description**: #{doc[:description]}\n"
        if doc[:params].any?
          file.puts "**Params:**"
          doc[:params].each do |p|
            file.puts "- `#{p[:name]}` (#{p[:type]}#{p[:required] ? ', required' : ''}) - #{p[:desc]}"
          end
        end
        if doc[:responses].any?
          file.puts "\n**Responses:**"
          doc[:responses].each { |r| file.puts "- `#{r[:code]}`: #{r[:desc]}" }
        end
        file.puts "\n---\n"
      end
    end
  end

  puts "✅ Exported documentation to docs/exported.md"
end

namespace :db do
  desc "Create the database"
  task :create do
    uri = URI.parse(ENV['DATABASE_URL'])
    dbname = uri.path[1..-1]
    conn = PG.connect(dbname: 'postgres', user: uri.user, password: uri.password, host: uri.host)
    begin
      conn.exec("CREATE DATABASE #{dbname}")
      puts "✅ Database '#{dbname}' created"
    rescue PG::DuplicateDatabase
      puts "⚠️  Database already exists: #{dbname}"
    ensure
      conn.close
    end
  end

  desc "Run all migrations"
  task :migrate do
    Dir.glob("db/migrate/*.rb").sort.each do |file|
      puts "🔧 Running #{file}"
      require_relative "./#{file}"
    end
  end

  desc "Drop the database"
  task :drop do
    uri = URI.parse(ENV['DATABASE_URL'])
    dbname = uri.path[1..-1]

    # Connect to a different DB like `postgres`
    conn = PG.connect(
      dbname: 'postgres',
      host: uri.host,
      user: uri.user,
      password: uri.password
    )

    begin
      # Terminate all connections to the DB we're dropping
      conn.exec <<~SQL
        REVOKE CONNECT ON DATABASE #{dbname} FROM public;
        SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '#{dbname}';
      SQL

      # Drop it
      conn.exec("DROP DATABASE IF EXISTS #{dbname}")
      puts "🗑️  Dropped database: #{dbname}"
    ensure
      conn.close
    end
  end

  desc "Seed the database"
  task :seed do
    load './db/seeds.rb'
  end
end

desc "Run the test suite"
task :test do
  sh "bundle exec rspec"
end
