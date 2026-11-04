require "rails_helper"

RSpec.describe MovementSerializer do
    let(:category) { build :category, name: "Supermercado" }
    let(:movement) { build :movement, user: category.user, category: category, amount: 1500.5, payment_method: "credit_card", credit_card: "amex", notes: "una nota" }
    let(:expected_serialization) { {
        id: movement.id,
        kind: "expense",
        date: movement.date,
        description: movement.description,
        amount: "1500.50",
        currency: "ARS",
        category_id: category.id,
        category: "Supermercado",
        subcategory: nil,
        event_id: nil,
        payment_method: "credit_card",
        credit_card: "amex",
        beneficiary: nil,
        notes: "una nota",
        shared: false
    } }
    let(:serialized_object) { movement.serialize }

    it "renders movement correctly" do
        expect(serialized_object).to eq expected_serialization
    end

    context "when the category is a subcategory" do
        let(:category) { build :category, :subcategory, name: "Almacén" }

        it "renders the root category and the subcategory names" do
            expect(serialized_object).to include(category: category.parent.name, subcategory: "Almacén")
        end
    end

    context "without category" do
        let(:movement) { build :movement, :without_category }

        it "renders null category fields" do
            expect(serialized_object).to include(category_id: nil, category: nil, subcategory: nil)
        end
    end
end
