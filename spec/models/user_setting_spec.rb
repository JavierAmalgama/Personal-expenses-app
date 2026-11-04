require "rails_helper"

RSpec.describe UserSetting, type: :model do
    subject { build :user_setting }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_numericality_of(:monthly_budget).is_greater_than(0).allow_nil }
    it { is_expected.to validate_inclusion_of(:budget_currency).in_array(Movement::SUPPORTED_CURRENCIES).with_message("must be one of: ARS, USD") }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:monthly_budget).of_type(:decimal).with_options(precision: 12, scale: 2) }
        it { is_expected.to have_db_column(:budget_currency).of_type(:string).with_options(null: false, default: "ARS") }
        it { is_expected.to have_db_index(:user_id).unique }
    end

    describe "one setting per user" do
        let!(:setting) { create :user_setting }

        it { expect(build :user_setting, user: setting.user).to be_invalid }
    end
end
