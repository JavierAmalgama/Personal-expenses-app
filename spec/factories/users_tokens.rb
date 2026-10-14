FactoryBot.define do
    factory :users_token do
        user
        sequence(:token) { |n| "xxxx#{n}!" }
    end
end