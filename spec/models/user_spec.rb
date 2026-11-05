require "rails_helper"

RSpec.describe User, type: :model do
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to have_many(:tokens).class_name("UsersToken") }
    it { is_expected.to have_many(:movements).dependent(:destroy) }
    it { is_expected.to have_many(:categories).dependent(:destroy) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_one(:setting).class_name("UserSetting").dependent(:destroy) }

    describe "db columns" do
        it { is_expected.to have_db_column(:id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:email).of_type(:string).with_options(null: false) }
    end

    describe "uniqueness validations" do
        let!(:user) { create :user }
        it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    end

    describe "email format" do
        [ "x", "x@x.", "x.com" ].each do |bad_email|
            context "when email is #{bad_email}" do
                let(:user) { build :user, email: bad_email }    
                it { expect(user).not_to be_valid }
            end
        end
        
        context "when email is valid" do
            let(:user) { build :user, email: "algo@otracosa.algomas" }
            it { expect(user).to be_valid }
        end
    end 

end
