# frozen_string_literal: true

require_relative '../app/models/user'
require_relative '../app/models/tag'
require_relative '../app/models/user_tag'
require_relative '../app/models/like'
require_relative '../app/models/blocked_user'
require_relative '../app/models/profile_view'
require_relative '../app/models/picture'
require_relative '../app/models/connection'
require_relative '../app/models/message'
require_relative '../app/models/date'
require_relative '../app/models/notification'

require 'faker'
require 'ruby-progressbar'
require 'time'

VERBOSE = true
LOG = Hash.new { |h, k| h[k] = [] }
TOTALUSERS = 100

puts '🌱 Seeding database...'

summary = {
  tags: [],
  users: [],
  links: [],
  pictures: [],
  likes: [],
  views: [],
  blocks: []
}

# ---------------------------
# Tags
# ---------------------------
puts '📌 Creating Tags...'
tag_names = %w[music hiking gaming vegan yoga books travel art dogs cats cooking dancing]
tag_bar = ProgressBar.create(title: 'Tags', total: tag_names.size)
tags = tag_names.map do |name|
  tag_bar.increment
  tag = Tag.find_by_name(name) || Tag.create(name)
  summary[:tags] << tag['name']
  LOG[:tags] << "➕ Tag: #{name}"
  tag
end

# ---------------------------
# Main Test User
# ---------------------------
puts '👤 Creating test user...'
main_user = User.find_by_username('testuser') || User.create({
                                                               username: 'testuser',
                                                               email: 'test@example.com',
                                                               password: 'testuser',
                                                               first_name: 'Test',
                                                               last_name: 'User',
                                                               gender: 'other',
                                                               sexual_preferences: 'everyone',
                                                               birth_year: '2000'
                                                             })
User.confirm!('testuser')
summary[:users] << 'testuser'
LOG[:users] << '✅ Created: testuser'

UserTag.add_tag(main_user['id'], tags[0]['id'])
UserTag.add_tag(main_user['id'], tags[2]['id'])
UserTag.add_tag(main_user['id'], tags[5]['id'])
summary[:links] << ['testuser', [tags[0]['name'], tags[2]['name'], tags[5]['name']]]
LOG[:links] << '🔗 Added tags to testuser'

# ---------------------------
# Fake Users
# ---------------------------
puts '👥 Creating fake users...'
users = [main_user]
usernames = TOTALUSERS.times.map { Faker::Internet.unique.username(specifier: 5..10) }
user_bar = ProgressBar.create(title: 'Users', total: usernames.size)

usernames.each do |username|
  user_bar.increment

  user = User.find_by_username(username) || User.create({
                                                          username: username,
                                                          email: Faker::Internet.email(name: username),
                                                          password: username,
                                                          first_name: Faker::Name.first_name,
                                                          last_name: Faker::Name.last_name,
                                                          gender: %w[male female other].sample,
                                                          sexual_preferences: %w[male female non_binary everyone].sample,
                                                          birth_year: Faker::Number.between(from: 1970, to: 2006)
                                                        })
  User.confirm!(user['username'])

  lat_offset = rand(-1.8..1.8)
  lon_offset = rand(-1.8..1.8)
  User.update(user['id'], {
                latitude: 19.43 + lat_offset,
                longitude: -99.13 + lon_offset
              })

  users << user
  summary[:users] << username
  LOG[:users] << "👤 Created user: #{username}"

  sample_tags = tags.sample(rand(1..3))
  sample_tags.each do |tag|
    UserTag.add_tag(user['id'], tag['id'])
    summary[:links] << [username, [tag['name']]]
    LOG[:links] << "   🔗 #{username} tagged with #{tag['name']}"
  end

  # pic_url = Faker::Avatar.image(slug: username)
  pic_url = "https://i.pravatar.cc/300?u=#{username}"
  pic = Picture.create(user['id'], pic_url, is_profile: true)
  User.update(user['id'], { "profile_picture_id": pic['id'] })
  summary[:pictures] << username
  LOG[:pictures] << "   🖼️ #{username} profile picture added"
end

# ---------------------------
# Blocked Users
# ---------------------------
puts '🚫 Blocking users...'
combos = users.combination(2).to_a
blocked_map = Hash.new { |h, k| h[k] = Set.new }
block_bar = ProgressBar.create(title: 'Blocks', total: combos.size)

combos.each do |u1, u2|
  block_bar.increment
  next unless rand < 0.002

  BlockedUser.block!(u1['id'], u2['id'])
  blocked_map[u1['id']] << u2['id']
  summary[:blocks] << "#{u1['username']} ⛔ #{u2['username']}"
  LOG[:blocks] << "🚫 #{u1['username']} blocked #{u2['username']}"
end

# ---------------------------
# Discoverable Users Cache
# ---------------------------
puts '🔍 Caching discoverable users...'
discover_map = {}
discover_bar = ProgressBar.create(title: 'Discoverables', total: users.size)

users.each do |user|
  discover_bar.increment
  discover_map[user['id']] = User.discover(user).map { |u| u[:user]['id'] }
end

# ---------------------------
# Likes and Views
# ---------------------------
puts '💘 Creating interactions (likes, views)...'
likes = {}
interaction_bar = ProgressBar.create(title: 'Interactions', total: combos.size)

combos.each do |u1, u2|
  interaction_bar.increment

  next if blocked_map[u1['id']].include?(u2['id']) || blocked_map[u2['id']].include?(u1['id'])
  next unless discover_map[u1['id']].include?(u2['id']) && discover_map[u2['id']].include?(u1['id'])

  if rand < 0.4
    Like.like!(u1['id'], u2['id'])
    (likes[u1['id']] ||= Set.new) << u2['id']
    summary[:likes] << "#{u1['username']} → #{u2['username']}"
    LOG[:likes] << "❤️ #{u1['username']} liked #{u2['username']}"
    Notification.create(u2['id'], "#{u1['username']} liked your profile", u1['id'], 'like')
    LOG[:notifications] << "🔔 #{u1['username']} → #{u2['username']} (like)"
  end

  if rand < 0.3
    Like.like!(u2['id'], u1['id'])
    (likes[u2['id']] ||= Set.new) << u1['id']
    summary[:likes] << "#{u2['username']} → #{u1['username']}"
    LOG[:likes] << "❤️ #{u2['username']} liked #{u1['username']}"
    Notification.create(u1['id'], "#{u2['username']} liked your profile", u2['id'], 'like')
    LOG[:notifications] << "🔔 #{u2['username']} → #{u1['username']} (like)"
  end

  if rand < 0.5
    ProfileView.record(u1['id'], u2['id'])
    summary[:views] << "#{u1['username']} → #{u2['username']}"
    LOG[:views] << "👀 #{u1['username']} viewed #{u2['username']}"
    Notification.create(u2['id'], "#{u1['username']} viewed your profile", u1['id'], 'like')
    LOG[:notifications] << "🔔 #{u1['username']} → #{u2['username']} (view)"
  end

  next unless rand < 0.5

  ProfileView.record(u2['id'], u1['id'])
  summary[:views] << "#{u2['username']} → #{u1['username']}"
  LOG[:views] << "👀 #{u2['username']} viewed #{u1['username']}"
  Notification.create(u1['id'], "#{u2['username']} viewed your profile", u2['id'], 'like')
  LOG[:notifications] << "🔔 #{u1['username']} → #{u2['username']} (view)"
end

# ---------------------------
# Connections
# ---------------------------
puts '🔗 Creating connections for matches...'
connection_bar = ProgressBar.create(title: 'Connections', total: users.size)

users.each do |u1|
  connection_bar.increment
  (likes[u1['id']] || []).each do |liked_id|
    next unless likes[liked_id]&.include?(u1['id'])

    conn = Connection.create(u1['id'], liked_id)
    if conn
      u2 = users.find { |u| u['id'] == liked_id }
      LOG[:connections] << "🔗 #{u1['username']} ↔ #{u2['username']}"
    end
  end
end

# ---------------------------
# Messages
# ---------------------------
puts '✉️ Generating messages...'
message_bar = ProgressBar.create(title: 'Messages', total: users.size)

users.each do |user|
  message_bar.increment
  User.connections(user['id']).each do |partner|
    conn = Connection.find_between(user['id'], partner['id'])
    next unless conn

    rand(1..3).times do
      content = Faker::Lorem.sentence(word_count: rand(4..10))
      Message.create(conn['id'], user['id'], content)
      LOG[:messages] << "✉️ #{user['username']} → #{partner['username']}: #{content}"
      Notification.create(partner['id'], "#{user['username']} sent you a message", user['id'], 'message')
      LOG[:notifications] << "🔔 #{user['username']} → #{partner['username']} (message)"
    end
  end
end

# ---------------------------
# Dates
# ---------------------------
puts '📅 Scheduling dates...'
date_count = users.sum { |user| User.connections(user['id']).size }
date_bar = ProgressBar.create(title: 'Dates', total: date_count)

users.each do |user|
  User.connections(user['id']).each do |partner|
    date_bar.increment
    conn = Connection.find_between(user['id'], partner['id'])
    next unless conn
    next unless rand < 0.02

    time = Faker::Time.forward(days: rand(1..30), period: :evening).iso8601
    location = Faker::Address.city
    description = Faker::Lorem.sentence(word_count: 5)

    Date.create(conn['id'], user['id'], location, time, description)
    parsed_time = Time.parse(time.to_s)
    LOG[:dates] << "📅 #{user['username']} scheduled a date with #{partner['username']} at #{location} on #{parsed_time.strftime('%F %H:%M')}"
  end
end

# ---------------------------
# Final Summary
# ---------------------------
puts "\n✅ Done seeding!\n\n"

puts "👤 Users created: (#{summary[:users].size})"
puts "🏷️ Tags created: (#{summary[:tags].size})"
puts "🖼️ Pictures added: (#{summary[:pictures].size})"
puts "🔗 User-Tag links: (#{summary[:links].size})"
puts "❤️ Likes: (#{summary[:likes].size})"
puts "👀 Views: (#{summary[:views].size})"
puts "🚫 Blocks: (#{summary[:blocks].size})"
puts "🔗 Connections: (#{LOG[:connections].size})"
puts "✉️ Messages: (#{LOG[:messages].size})"
puts "📅 Dates: (#{LOG[:dates].size})"
puts "🔔 Notifications: (#{LOG[:notifications].size})"

if VERBOSE
  puts "\n📘 Detailed Log:\n"
  LOG.each do |section, lines|
    puts "\n🔹 #{section.capitalize} (#{lines.size})"
    lines.each { |line| puts "  #{line}" }
  end
end
