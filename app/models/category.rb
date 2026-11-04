class Category < ApplicationRecord
    belongs_to :user
    belongs_to :parent, class_name: "Category", optional: true
    has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
    has_many :movements, dependent: :nullify

    enum :kind, { income: "income", expense: "expense" }, validate: true

    validates :name, presence: true, uniqueness: { scope: [ :user_id, :parent_id ], case_sensitive: false }
    validate :parent_is_compatible, if: :parent

    scope :roots, -> { where(parent_id: nil) }

    private

    def parent_is_compatible
        errors.add(:parent, "must belong to the same user") if parent.user_id != user_id
        errors.add(:parent, "must have the same kind") if parent.kind != kind
        errors.add(:parent, "can't be a subcategory") if parent.parent_id.present?
    end
end
