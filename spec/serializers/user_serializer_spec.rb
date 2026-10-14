require "rails_helper"

RSpec.describe UserSerializer do
    let(:user) { build :user }
    let(:expected_serialization) { {
        id: user.id,
        name: user.name,
        email: user.email
    } }
    let(:serialized_object) { user.serialize }
    
    it "renders user correctly" do
        expect(serialized_object).to eq expected_serialization
    end

end