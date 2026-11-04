require "rails_helper"

RSpec.describe Event, type: :model do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:movements).dependent(:nullify) }
    it { is_expected.to validate_presence_of(:name) }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    end
end
