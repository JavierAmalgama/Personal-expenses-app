require "rails_helper"

RSpec.describe Category, type: :model do
    subject { build :category }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:parent).class_name("Category").optional }
    it { is_expected.to have_many(:subcategories).class_name("Category").dependent(:destroy) }
    it { is_expected.to have_many(:movements).dependent(:nullify) }
    it { is_expected.to validate_presence_of(:name) }

    describe "db columns" do
        it { is_expected.to have_db_column(:user_id).of_type(:integer).with_options(null: false) }
        it { is_expected.to have_db_column(:parent_id).of_type(:integer) }
        it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
        it { is_expected.to have_db_column(:kind).of_type(:enum).with_options(null: false) }
    end

    describe "kind" do
        it { expect(build :category, kind: "income").to be_valid }
        it { expect(build :category, kind: "gift").to be_invalid }
    end

    describe "name uniqueness" do
        let(:user) { create :user }
        let!(:existing) { create :category, user: user, name: "Vivienda" }

        it { expect(build :category, user: user, name: "vivienda").to be_invalid }
        it { expect(build :category, name: "Vivienda").to be_valid }
        it { expect(build :category, user: user, parent: existing, name: "Vivienda").to be_valid }

        it "is enforced by the database for root categories" do
            duplicated = build :category, user: user, name: "Vivienda"
            expect { duplicated.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        end
    end

    describe "parent" do
        let(:parent) { create :category }

        it { expect(build :category, user: parent.user, parent: parent).to be_valid }
        it { expect(build :category, parent: parent).to be_invalid }
        it { expect(build :category, user: parent.user, parent: parent, kind: "income").to be_invalid }

        it "allows only one level of nesting" do
            subcategory = create :category, :subcategory
            expect(build :category, user: subcategory.user, parent: subcategory).to be_invalid
        end
    end
end
