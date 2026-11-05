require "rails_helper"

RSpec.describe Movement, type: :model do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to belong_to(:event).optional }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:kind).of_type(:enum).with_options(null: false) }
        it { is_expected.to have_db_column(:date).of_type(:date).with_options(null: false) }
        it { is_expected.to have_db_column(:description).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:amount).of_type(:decimal).with_options(null: false, precision: 12, scale: 2) }
        it { is_expected.to have_db_column(:currency).of_type(:enum).with_options(null: false, default: "ARS") }
        it { is_expected.to have_db_column(:category_id).of_type(:integer) }
        it { is_expected.to have_db_column(:event_id).of_type(:integer) }
        it { is_expected.not_to have_db_column(:category) }
        it { is_expected.not_to have_db_column(:subcategory) }
        it { is_expected.to have_db_column(:payment_method).of_type(:enum) }
        it { is_expected.to have_db_column(:credit_card).of_type(:enum) }
        it { is_expected.to have_db_column(:beneficiary).of_type(:string) }
        it { is_expected.to have_db_column(:notes).of_type(:text) }
        it { is_expected.to have_db_column(:shared).of_type(:boolean).with_options(null: false, default: false) }
        it { is_expected.to have_db_column(:offset_data).of_type(:jsonb) }
    end

    describe "db enums" do
        let(:movement) { create :movement }

        # update_column skips the model validations, so only the Postgres enum type stands in the way.
        {
            kind: "gift",
            currency: "EUR",
            payment_method: "bitcoin",
            credit_card: "mastercard"
        }.each do |column, value|
            it "rejects #{value} as #{column} at the database level" do
                expect { movement.update_column(column, value) }
                    .to raise_error(ActiveRecord::StatementInvalid, /invalid input value for enum/)
            end
        end
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

    describe "currency" do
        it { is_expected.to validate_inclusion_of(:currency).in_array(Movement::SUPPORTED_CURRENCIES).with_message("must be one of: ARS, USD") }

        [ "ars", "AR", "ARSS", "EUR", "" ].each do |bad_currency|
            context "when currency is '#{bad_currency}'" do
                it { expect(build :movement, currency: bad_currency).to be_invalid }
            end
        end

        context "when currency is USD" do
            it { expect(build :movement, currency: "USD").to be_valid }
        end
    end

    describe "category" do
        let(:user) { create :user }

        it { expect(build :movement, :without_category).to be_valid }
        it { expect(build :movement, user: user, category: create(:category, user: user)).to be_valid }
        it { expect(build :movement, user: user, category: create(:category)).to be_invalid }
        it { expect(build :movement, user: user, category: create(:category, user: user, kind: "income")).to be_invalid }
    end

    describe "event" do
        let(:user) { create :user }

        it { expect(build :movement, user: user, event: create(:event, user: user)).to be_valid }
        it { expect(build :movement, user: user, event: create(:event)).to be_invalid }
    end

    describe "offset_data" do
        let(:user) { create :user }
        let(:expense) { create :movement, user: user, amount: 10_000 }
        let(:offset_data) { { target_type: "movement", target_id: expense.id, amount: "4000" } }

        def reimbursement(**attributes)
            build :movement, :income, :without_category, user: user, amount: 4000, offset_data: offset_data, **attributes
        end

        it { expect(reimbursement).to be_valid }
        it { expect(build :movement, offset_data: nil).to be_valid }

        it "normalizes the target id and amount" do
            movement = reimbursement
            movement.offset_data = { "target_type" => "movement", "target_id" => expense.id.to_s, "amount" => 4000, "extra" => 1 }
            expect(movement.offset_data).to eq("target_type" => "movement", "target_id" => expense.id, "amount" => "4000.00")
        end

        it "can offset an event or an expense category" do
            expect(reimbursement(offset_data: { target_type: "event", target_id: create(:event, user: user).id, amount: 100 })).to be_valid
            expect(reimbursement(offset_data: { target_type: "category", target_id: create(:category, user: user).id, amount: 100 })).to be_valid
        end

        {
            "is only allowed on income movements" => { kind: "expense" },
            "must be an object" => { offset_data: "movement" },
            "target_type must be one of: movement, event, category" => { offset_data: { target_type: "user", target_id: 1, amount: 1 } },
            "target_id must be an integer" => { offset_data: { target_type: "movement", target_id: "abc", amount: 1 } },
            "amount must be a number greater than 0" => { offset_data: { target_type: "movement", target_id: 1, amount: -1 } },
            "amount can't exceed the movement amount" => { amount: 100 }
        }.each do |message, attributes|
            it "is invalid when #{message}" do
                movement = reimbursement(**attributes)
                expect(movement).to be_invalid
                expect(movement.errors[:offset_data]).to include(message)
            end
        end

        it "still checks the target when another attribute is invalid" do
            movement = reimbursement(description: nil, offset_data: { target_type: "movement", target_id: create(:movement).id, amount: 1 })
            expect(movement).to be_invalid
            expect(movement.errors[:offset_data]).to include("target must be an expense of the same user")
        end

        it "doesn't raise without a user" do
            expect(reimbursement(user: nil)).to be_invalid
        end

        context "when the target isn't an expense of the same user" do
            it "is invalid for a movement of another user" do
                movement = reimbursement(offset_data: { target_type: "movement", target_id: create(:movement).id, amount: 1 })
                expect(movement).to be_invalid
                expect(movement.errors[:offset_data]).to include("target must be an expense of the same user")
            end

            it "is invalid for an income movement" do
                income = create :movement, :income, :without_category, user: user
                movement = reimbursement(offset_data: { target_type: "movement", target_id: income.id, amount: 1 })
                expect(movement).to be_invalid
                expect(movement.errors[:offset_data]).to include("target must be an expense of the same user")
            end
        end

        describe ".offsetting and .offset_total" do
            let!(:first) { create :movement, :reimbursement, user: user, offset_target: expense, amount: 1500 }
            let!(:second) { create :movement, :reimbursement, user: user, offset_target: expense, amount: 2500.5 }
            let!(:other) { create :movement, :reimbursement, user: user, amount: 999 }

            it "finds the reimbursements of a target with the @> operator" do
                expect(Movement.offsetting("movement", expense.id)).to contain_exactly(first, second)
            end

            it "adds up the reimbursed amount from the json" do
                expect(Movement.offset_total("movement", expense.id)).to eq BigDecimal("4000.50")
            end
        end
    end

    describe "scopes" do
        let(:user) { create :user }
        let(:housing) { create :category, user: user, name: "Vivienda" }
        let(:rent) { create :category, user: user, name: "Alquiler", parent: housing }
        let!(:october_expense) { create :movement, user: user, date: Date.new(2026, 10, 31), category: rent }
        let!(:october_income) { create :movement, :income, user: user, date: Date.new(2026, 10, 1) }
        let!(:september_expense) { create :movement, user: user, date: Date.new(2026, 9, 30) }

        it "filters by month" do
            expect(Movement.in_month(Date.new(2026, 10, 15))).to contain_exactly(october_expense, october_income)
        end

        it "filters by category" do
            expect(Movement.with_category(rent.id)).to contain_exactly(october_expense)
        end

        it "includes the subcategories when filtering by a root category" do
            housing_expense = create :movement, user: user, category: housing
            expect(Movement.with_category(housing.id)).to contain_exactly(october_expense, housing_expense)
        end

        it "filters by kind" do
            expect(Movement.of_kind("income")).to contain_exactly(october_income)
        end
    end
end
