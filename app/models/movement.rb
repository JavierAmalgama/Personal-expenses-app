class Movement < ApplicationRecord
    SUPPORTED_CURRENCIES = %w[ARS USD].freeze

    belongs_to :user
    belongs_to :category, optional: true
    belongs_to :event, optional: true

    enum :kind, { income: "income", expense: "expense" }, validate: true
    enum :payment_method, {
        cash: "cash",
        debit_card: "debit_card",
        credit_card: "credit_card",
        transfer: "transfer",
        other: "other"
    }, prefix: true, validate: { allow_nil: true }
    enum :credit_card, {
        visa: "visa",
        amex: "amex",
        mercado_pago: "mercado_pago",
        other: "other"
    }, prefix: true, validate: { allow_nil: true }

    validates :credit_card, presence: true, if: :payment_method_credit_card?
    validates :credit_card, absence: true, unless: :payment_method_credit_card?

    validates :date, :description, presence: true
    validates :amount,
        presence: true,
        numericality: { greater_than: 0 }
    validates :currency,
        presence: true,
        inclusion: { in: SUPPORTED_CURRENCIES, message: "must be one of: #{SUPPORTED_CURRENCIES.join(', ')}" }

    validate :category_is_compatible, if: :category
    validate :event_belongs_to_user, if: :event

    scope :in_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
    scope :with_category, ->(category_id) {
        where(category_id: Category.where(id: category_id).or(Category.where(parent_id: category_id)).select(:id))
    }
    scope :of_kind, ->(kind) { where(kind: kind) }

    private

    def category_is_compatible
        errors.add(:category, "must belong to the same user") if category.user_id != user_id
        errors.add(:category, "must have the same kind as the movement") if category.kind != kind
    end

    def event_belongs_to_user
        errors.add(:event, "must belong to the same user") if event.user_id != user_id
    end
end
