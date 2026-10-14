class Movement < ApplicationRecord
    belongs_to :user

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
        format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code like 'ARS'" }

    scope :in_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
    scope :with_category, ->(category) { where(category: category) }
    scope :of_kind, ->(kind) { where(kind: kind) }
end
