class Movement < ApplicationRecord
    SUPPORTED_CURRENCIES = %w[ARS USD].freeze
    OFFSET_TARGETS = { "movement" => :movements, "event" => :events, "category" => :categories }.freeze

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
    validate :offset_data_is_valid, if: :offset_data

    scope :in_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
    scope :with_category, ->(category_id) {
        where(category_id: Category.where(id: category_id).or(Category.where(parent_id: category_id)).select(:id))
    }
    scope :of_kind, ->(kind) { where(kind: kind) }
    # @> (containment) is the operator the GIN index on offset_data can serve.
    scope :offsetting, ->(target_type, target_id) {
        where("offset_data @> ?", { target_type: target_type, target_id: target_id }.to_json)
    }

    def self.offset_total(target_type, target_id)
        offsetting(target_type, target_id).sum(Arel.sql("(offset_data->>'amount')::numeric"))
    end

    def offset_data=(value)
        value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
        super(value.is_a?(Hash) ? normalize_offset_data(value.stringify_keys) : value)
    end

    private

    def category_is_compatible
        errors.add(:category, "must belong to the same user") if category.user_id != user_id
        errors.add(:category, "must have the same kind as the movement") if category.kind != kind
    end

    def event_belongs_to_user
        errors.add(:event, "must belong to the same user") if event.user_id != user_id
    end

    def normalize_offset_data(data)
        data.slice("target_type", "target_id", "amount").merge(
            "target_id" => Integer(data["target_id"], exception: false) || data["target_id"],
            "amount" => normalize_offset_amount(data["amount"])
        )
    end

    def normalize_offset_amount(amount)
        format("%.2f", BigDecimal(amount.to_s))
    rescue ArgumentError
        amount
    end

    def offset_data_is_valid
        return errors.add(:offset_data, "is only allowed on income movements") unless income?
        return errors.add(:offset_data, "must be an object") unless offset_data.is_a?(Hash)

        target_type, target_id, amount = offset_data.values_at("target_type", "target_id", "amount")
        shape_errors = [
            ("target_type must be one of: #{OFFSET_TARGETS.keys.join(', ')}" unless OFFSET_TARGETS.key?(target_type)),
            ("target_id must be an integer" unless target_id.is_a?(Integer)),
            ("amount must be a number greater than 0" unless amount.is_a?(String) && amount.to_d.positive?)
        ].compact
        shape_errors.each { |message| errors.add(:offset_data, message) }
        return if shape_errors.any?

        errors.add(:offset_data, "amount can't exceed the movement amount") if amount.to_d > self.amount.to_d
        errors.add(:offset_data, "target must be an expense of the same user") unless offset_target_valid?(target_type, target_id)
    end

    def offset_target_valid?(target_type, target_id)
        return false unless user

        targets = user.public_send(OFFSET_TARGETS[target_type])
        targets = targets.where(kind: "expense") unless target_type == "event"
        targets.exists?(target_id)
    end
end
