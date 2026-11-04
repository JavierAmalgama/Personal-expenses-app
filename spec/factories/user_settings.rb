FactoryBot.define do
    factory :user_setting do
        user
        monthly_budget { 500_000 }
        budget_currency { "ARS" }
    end
end
