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

def demo_category(user, kind, name, subcategory = nil)
  root = user.categories.find_or_create_by!(name: name, parent: nil) { |c| c.kind = kind }
  return root unless subcategory

  user.categories.find_or_create_by!(name: subcategory, parent: root) { |c| c.kind = kind }
end

[
  { kind: "income", date: Date.current.beginning_of_month, description: "Sueldo", amount: 850_000,
    category: [ "Sueldo" ], payment_method: "transfer" },
  { kind: "expense", date: Date.current.beginning_of_month + 4, description: "Alquiler", amount: 320_000,
    category: [ "Vivienda", "Alquiler" ], payment_method: "transfer", beneficiary: "Inmobiliaria" },
  { kind: "expense", date: Date.current - 2, description: "Compra semanal", amount: 45_870.50,
    category: [ "Comida", "Supermercado" ], payment_method: "debit_card", beneficiary: "Coto", shared: true },
  { kind: "expense", date: Date.current - 3, description: "Uber al centro", amount: 8_500,
    category: [ "Transporte", "Uber / Taxi" ], payment_method: "credit_card", credit_card: "amex" },
  { kind: "expense", date: Date.current - 1, description: "Netflix", amount: 12.99, currency: "USD",
    category: [ "Suscripciones" ], payment_method: "credit_card", credit_card: "visa" }
].each do |attributes|
  category = demo_category(user, attributes[:kind], *attributes[:category])
  user.movements.find_or_create_by!(attributes.slice(:date, :description)) do |movement|
    movement.assign_attributes(attributes.merge(category: category))
  end
end

puts "Demo movements: #{user.movements.count}"
