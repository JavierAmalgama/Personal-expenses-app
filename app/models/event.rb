class Event < ApplicationRecord
    belongs_to :user
    has_many :movements, dependent: :nullify

    validates :name, presence: true
end
