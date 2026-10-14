# Idempotent: creates a demo user with a fixed, non-expiring token so the API can be
# used from Swagger (/api-docs) and the front without a login endpoint.
DEV_TOKEN = ENV.fetch("DEV_API_TOKEN", "dev-token-123!")

user = User.find_or_create_by!(email: "demo@finances.test") do |u|
  u.name = "Demo"
end

UsersToken.find_or_create_by!(token: DEV_TOKEN) do |t|
  t.user = user
end

puts "Demo user: #{user.email} — Authorization: #{DEV_TOKEN}"
