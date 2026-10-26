class MovementSerializer < ActiveModel::Serializer
    attributes :id, :kind, :date, :description, :amount, :currency, :category,
        :subcategory, :payment_method, :credit_card, :beneficiary, :notes, :shared

    def amount
        format("%.2f", object.amount)
    end
end
