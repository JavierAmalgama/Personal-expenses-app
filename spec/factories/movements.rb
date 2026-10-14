FactoryBot.define do
    factory :movement do
        user
        kind { "expense" }
        date { Date.current }
        sequence(:description) { |n| "movement #{n}" }
        amount { 1500.50 }
        currency { "ARS" }
        category { "Supermercado" }

        trait :income do
            kind { "income" }
            category { "Sueldo" }
        end
    end
end
