class MovementSerializer < ActiveModel::Serializer
    attributes :id, :kind, :date, :description, :amount, :currency, :category_id, :category,
        :subcategory, :event_id, :payment_method, :credit_card, :beneficiary, :notes, :shared,
        :offset_data

    def amount
        format("%.2f", object.amount)
    end

    def category
        root_category&.name
    end

    def subcategory
        object.category&.parent ? object.category.name : nil
    end

    private

    def root_category
        object.category&.parent || object.category
    end
end
