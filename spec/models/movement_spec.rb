require "rails_helper"

RSpec.describe Movement, type: :model do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:kind).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:date).of_type(:date).with_options(null: false) }
        it { is_expected.to have_db_column(:description).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:amount).of_type(:decimal).with_options(null: false, precision: 12, scale: 2) }
        it { is_expected.to have_db_column(:currency).of_type(:string).with_options(null: false, default: "ARS") }
        it { is_expected.to have_db_column(:category).of_type(:string) }
        it { is_expected.to have_db_column(:subcategory).of_type(:string) }
        it { is_expected.to have_db_column(:payment_method).of_type(:string) }
        it { is_expected.to have_db_column(:credit_card).of_type(:string) }
        it { is_expected.to have_db_column(:beneficiary).of_type(:string) }
        it { is_expected.to have_db_column(:notes).of_type(:text) }
        it { is_expected.to have_db_column(:shared).of_type(:boolean).with_options(null: false, default: false) }
    end

    describe "kind" do
        it { expect(build :movement, kind: "income").to be_valid }
        it { expect(build :movement, kind: "expense").to be_valid }
        it { expect(build :movement, kind: "other").to be_invalid }
        it { expect(build :movement, kind: nil).to be_invalid }
    end

    describe "payment_method" do
        it { expect(build :movement, payment_method: nil).to be_valid }
        it { expect(build :movement, payment_method: "credit_card", credit_card: "visa").to be_valid }
        it { expect(build :movement, payment_method: "bitcoin").to be_invalid }
    end

    describe "credit_card" do
        context "when paid with credit card" do
            [ "visa", "amex", "mercado_pago", "other" ].each do |card|
                it { expect(build :movement, payment_method: "credit_card", credit_card: card).to be_valid }
            end
            it { expect(build :movement, payment_method: "credit_card", credit_card: nil).to be_invalid }
            it { expect(build :movement, payment_method: "credit_card", credit_card: "mastercard").to be_invalid }
        end

        context "when not paid with credit card" do
            it { expect(build :movement, payment_method: "cash", credit_card: nil).to be_valid }
            it { expect(build :movement, payment_method: "cash", credit_card: "visa").to be_invalid }
            it { expect(build :movement, payment_method: nil, credit_card: "visa").to be_invalid }
        end
    end

    describe "currency format" do
        [ "ars", "AR", "ARSS", "" ].each do |bad_currency|
            context "when currency is '#{bad_currency}'" do
                it { expect(build :movement, currency: bad_currency).to be_invalid }
            end
        end

        context "when currency is USD" do
            it { expect(build :movement, currency: "USD").to be_valid }
        end
    end

    describe "scopes" do
        let(:user) { create :user }
        let!(:october_expense) { create :movement, user: user, date: Date.new(2026, 10, 31), category: "Alquiler" }
        let!(:october_income) { create :movement, :income, user: user, date: Date.new(2026, 10, 1) }
        let!(:september_expense) { create :movement, user: user, date: Date.new(2026, 9, 30) }

        it "filters by month" do
            expect(Movement.in_month(Date.new(2026, 10, 15))).to contain_exactly(october_expense, october_income)
        end

        it "filters by category" do
            expect(Movement.with_category("Alquiler")).to contain_exactly(october_expense)
        end

        it "filters by kind" do
            expect(Movement.of_kind("income")).to contain_exactly(october_income)
        end
    end
end
