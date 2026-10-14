FactoryBot.define do
	factory :user do
		email { "user#{SecureRandom.hex(4)}@test.com" }
		sequence(:name) { |n| "name #{n}" }
		
		trait :with_valid_token do
			tokens { [ build(:users_token) ] }
		end
	end
end
