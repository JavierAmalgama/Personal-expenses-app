namespace :perf do
  desc "Bulk-inserts fake movements so EXPLAIN ANALYZE has enough rows to choose an index (default 100_000)"
  task :seed_movements, [ :count ] => :environment do |_task, args|
    abort "perf:seed_movements only runs in development" unless Rails.env.development?

    count = Integer(args[:count] || 100_000)
    users = Array.new(20) do |i|
      User.find_or_create_by!(email: "perf-#{i}@finances.test") { |u| u.name = "Perf #{i}" }
    end
    now = Time.current
    random = Random.new(42)

    count.times.each_slice(5_000) do |batch|
      rows = batch.map do
        payment_method = Movement.payment_methods.keys.sample(random: random)
        {
          user_id: users.sample(random: random).id,
          kind: random.rand < 0.85 ? "expense" : "income",
          date: Date.current - random.rand(3 * 365),
          description: "Perf movement",
          amount: random.rand(100..200_000),
          currency: random.rand < 0.9 ? "ARS" : "USD",
          payment_method: payment_method,
          credit_card: payment_method == "credit_card" ? Movement.credit_cards.keys.sample(random: random) : nil,
          created_at: now,
          updated_at: now
        }
      end
      Movement.insert_all(rows)
    end

    # Reimbursements reference expenses that already exist, so they go in a second pass.
    expenses = Movement.where(user_id: users.map(&:id), kind: "expense").pluck(:id, :user_id, :date)
    reimbursements = expenses.sample(count / 10, random: random).map do |expense_id, user_id, date|
      amount = random.rand(100..5_000)
      {
        user_id: user_id, kind: "income", date: date + 15, description: "Perf reimbursement", amount: amount,
        currency: "ARS", offset_data: { target_type: "movement", target_id: expense_id, amount: format("%.2f", amount) },
        created_at: now, updated_at: now
      }
    end
    reimbursements.each_slice(5_000) { |rows| Movement.insert_all(rows) }

    ActiveRecord::Base.connection.execute("ANALYZE movements")
    puts "movements: #{Movement.count} (#{count} + #{reimbursements.size} reimbursements) across #{users.size} perf users"
  end
end
