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

[
  { kind: "income", date: Date.current.beginning_of_month, description: "Sueldo", amount: 850_000,
    category: "Sueldo", payment_method: "transfer" },
  { kind: "expense", date: Date.current.beginning_of_month + 4, description: "Alquiler", amount: 320_000,
    category: "Vivienda", subcategory: "Alquiler", payment_method: "transfer", beneficiary: "Inmobiliaria" },
  { kind: "expense", date: Date.current - 2, description: "Compra semanal", amount: 45_870.50,
    category: "Supermercado", payment_method: "debit_card", beneficiary: "Coto", shared: true },
  { kind: "expense", date: Date.current - 1, description: "Netflix", amount: 12.99, currency: "USD",
    category: "Suscripciones", payment_method: "credit_card", credit_card: "visa" }
].each do |attributes|
  user.movements.find_or_create_by!(attributes.slice(:date, :description)) do |movement|
    movement.assign_attributes(attributes)
  end
end

puts "Demo movements: #{user.movements.count}"
