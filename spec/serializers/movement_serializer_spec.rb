require "rails_helper"

RSpec.describe MovementSerializer do
    let(:movement) { build :movement, amount: 1500.5, payment_method: "credit_card", credit_card: "amex", notes: "una nota" }
    let(:expected_serialization) { {
        id: movement.id,
        kind: "expense",
        date: movement.date,
        description: movement.description,
        amount: "1500.50",
        currency: "ARS",
        category: "Supermercado",
        subcategory: nil,
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
end
