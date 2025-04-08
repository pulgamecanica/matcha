require_relative '../app/models/user'
require_relative '../app/models/tag'
require_relative '../app/models/user_tag'

puts "🌱 Seeding database..."

# Create tags
tags = %w[music hiking gaming vegan yoga books travel art].map do |name|
  Tag.find_by_name(name) || Tag.create(name)
end

# Create a user
user = User.find_by_username("testuser") || User.create({
  username: "testuser",
  email: "test@example.com",
  password: "secretpass",
  first_name: "Test",
  last_name: "User",
  gender: "other",
  sexual_preferences: "everyone"
})

User.confirm!("testuser")

# Assign some tags
UserTag.add_tag(user["id"], tags[0]["id"])  # music
UserTag.add_tag(user["id"], tags[2]["id"])  # gaming
UserTag.add_tag(user["id"], tags[5]["id"])  # travel

puts "✅ Done seeding!"
