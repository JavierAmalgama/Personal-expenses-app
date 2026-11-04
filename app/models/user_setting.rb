class UserSetting < ApplicationRecord
    belongs_to :user

    validates :user_id, uniqueness: true
    validates :monthly_budget, numericality: { greater_than: 0 }, allow_nil: true
    validates :budget_currency,
        inclusion: { in: Movement::SUPPORTED_CURRENCIES, message: "must be one of: #{Movement::SUPPORTED_CURRENCIES.join(', ')}" }
end
