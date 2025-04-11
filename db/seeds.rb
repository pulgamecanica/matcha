# frozen_string_literal: true

require_relative '../app/models/user'
require_relative '../app/models/tag'
require_relative '../app/models/user_tag'
require_relative '../app/models/like'
require_relative '../app/models/blocked_user'
require_relative '../app/models/profile_view'
require_relative '../app/models/picture'
require 'faker'
require 'ruby-progressbar'

VERBOSE = true
LOG = Hash.new { |h, k| h[k] = [] }

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
                                                               password: 'secretpass',
                                                               first_name: 'Test',
                                                               last_name: 'User',
                                                               gender: 'other',
                                                               sexual_preferences: 'everyone'
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
usernames = 10.times.map { Faker::Internet.unique.username(specifier: 5..10) }
user_bar = ProgressBar.create(title: 'Users', total: usernames.size)

usernames.each do |username|
  user_bar.increment

  user = User.find_by_username(username) || User.create({
                                                          username: username,
                                                          email: Faker::Internet.email(name: username),
                                                          password: 'password123',
                                                          first_name: Faker::Name.first_name,
                                                          last_name: Faker::Name.last_name,
                                                          gender: %w[male female other].sample,
                                                          sexual_preferences: %w[male female non_binary everyone].sample
                                                        })
  User.confirm!(user['username'])
  users << user
  summary[:users] << username
  LOG[:users] << "👤 Created user: #{username}"

  sample_tags = tags.sample(rand(1..3))
  sample_tags.each do |tag|
    UserTag.add_tag(user['id'], tag['id'])
    summary[:links] << [username, [tag['name']]]
    LOG[:links] << "   🔗 #{username} tagged with #{tag['name']}"
  end

  pic_url = Faker::Avatar.image(slug: username)
  Picture.create(user['id'], pic_url, is_profile: true)
  summary[:pictures] << username
  LOG[:pictures] << "   🖼️ #{username} profile picture added"
end

# ---------------------------
# Interactions
# ---------------------------
puts '💘 Connecting users...'
combos = users.combination(2).to_a
combo_bar = ProgressBar.create(title: 'Interactions', total: combos.size)

combos.each do |u1, u2|
  combo_bar.increment

  if rand < 0.4
    Like.like!(u1['id'], u2['id'])
    summary[:likes] << "#{u1['username']} → #{u2['username']}"
    LOG[:likes] << "❤️ #{u1['username']} liked #{u2['username']}"
  end

  if rand < 0.3
    Like.like!(u2['id'], u1['id'])
    summary[:likes] << "#{u2['username']} → #{u1['username']}"
    LOG[:likes] << "❤️ #{u2['username']} liked #{u1['username']}"
  end

  if rand < 0.5
    ProfileView.record(u1['id'], u2['id'])
    summary[:views] << "#{u1['username']} → #{u2['username']}"
    LOG[:views] << "👀 #{u1['username']} viewed #{u2['username']}"
  end

  if rand < 0.5
    ProfileView.record(u2['id'], u1['id'])
    summary[:views] << "#{u2['username']} → #{u1['username']}"
    LOG[:views] << "👀 #{u2['username']} viewed #{u1['username']}"
  end

  next unless rand < 0.1

  BlockedUser.block!(u1['id'], u2['id'])
  summary[:blocks] << "#{u1['username']} ⛔ #{u2['username']}"
  LOG[:blocks] << "🚫 #{u1['username']} blocked #{u2['username']}"
end

# ---------------------------
# Final Summary
# ---------------------------
puts "\n✅ Done seeding!\n\n"

puts "👤 Users created (#{summary[:users].size})"
puts "🏷️ Tags created (#{summary[:tags].size})"
puts "🖼️ Pictures added: #{summary[:pictures].size}"
puts "🔗 User-Tag links: #{summary[:links].size}"
puts "❤️ Likes: #{summary[:likes].size}"
puts "👀 Views: #{summary[:views].size}"
puts "🚫 Blocks: #{summary[:blocks].size}"

if VERBOSE
  puts "\n📘 Detailed Log:\n"

  LOG.each do |section, lines|
    puts "\n🔹 #{section.capitalize} (#{lines.size})"
    lines.each { |line| puts "  #{line}" }
  end
end
