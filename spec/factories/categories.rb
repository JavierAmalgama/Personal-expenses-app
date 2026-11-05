FactoryBot.define do
    factory :category do
        user
        sequence(:name) { |n| "Category #{n}" }
        kind { "expense" }

        trait :subcategory do
            parent { association :category, user: user, kind: kind }
        end
    end
end
