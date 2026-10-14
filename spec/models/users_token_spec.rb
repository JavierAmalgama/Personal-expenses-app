require "rails_helper"

RSpec.describe UsersToken, type: :model do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:token) }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:token).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:valid_until).of_type(:datetime).with_options(null: true) }
    end

    describe "uniqueness validations" do
        let!(:users_token) { create :users_token }
        it { is_expected.to validate_uniqueness_of(:token) }
    end
    
    describe "token format" do
        let!(:users_token) { build :users_token, token: token }
        context 'when valid' do
            let(:token) { "123ab!" }
            it { expect(users_token).to be_valid }
        end
        context "when it doesn't have numbers" do
            let(:token) { "abcdef!" }
            it { expect(users_token).to be_invalid }
        end
        context "when it doesn't have numbers" do
            let(:token) { "abcdef1" }
            it { expect(users_token).to be_invalid }
        end
        context "when it doesn't have letters" do
            let(:token) { "12345!" }
            it { expect(users_token).to be_invalid }
        end
        context "when it is shorter than six chars" do
            let(:token) { "a!345" }
            it { expect(users_token).to be_invalid }
        end
    end

    describe "#is_valid?" do
        context "when it doesn't have expiration" do
            it "should be valid" do
                token = build :users_token, valid_until: nil
                expect(token.is_valid?).to eq true
            end
        end

        context "when its expiration is later than now" do
            it "should be valid" do
                token = build :users_token, valid_until: 2.hours.after
                expect(token.is_valid?).to eq true
            end
        end

        context "when its expiration is past" do
            it "shouldn't be valid" do
                token = build :users_token, valid_until: 1.minute.before
                expect(token.is_valid?).to eq false
            end
        end
    end
end
