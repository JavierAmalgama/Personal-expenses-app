class UsersToken < ApplicationRecord
    TOKEN_REGEX = /(?=.*\d)(?=.*[a-zA-Z])(?=.*[\W_]).{6,}/
    belongs_to :user
    validates :token,
        presence: true,
        format: { with: TOKEN_REGEX, message: "Invalid token format."  },
        uniqueness: true

    def is_valid?
        self.valid_until == nil || self.valid_until > DateTime.now
    end
end