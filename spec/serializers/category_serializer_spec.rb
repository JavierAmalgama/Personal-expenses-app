require "rails_helper"

RSpec.describe CategorySerializer do
    let(:category) { build :category, :subcategory, name: "Almacén" }
    let(:expected_serialization) { {
        id: category.id,
        name: "Almacén",
        kind: "expense",
        parent_id: category.parent_id
    } }

    it "renders category correctly" do
        expect(category.serialize).to eq expected_serialization
    end
end
