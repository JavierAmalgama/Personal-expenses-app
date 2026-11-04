FactoryBot.define do
    factory :event do
        user
        sequence(:name) { |n| "Event #{n}" }
    end
end
