FactoryBot.define do
    factory :movement do
        user
        kind { "expense" }
        date { Date.current }
        sequence(:description) { |n| "movement #{n}" }
        amount { 1500.50 }
        currency { "ARS" }
        category { association :category, user: user, kind: kind }

        trait :income do
            kind { "income" }
        end

        trait :without_category do
            category { nil }
        end

        trait :reimbursement do
            income
            transient do
                offset_target { association :movement, user: user }
            end
            offset_data {
                { target_type: offset_target.class.name.underscore, target_id: offset_target.id, amount: amount }
            }
        end
    end
end
