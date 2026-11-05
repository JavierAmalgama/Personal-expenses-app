class User < ApplicationRecord
    has_many :tokens, class_name: "UsersToken"
    has_many :movements, dependent: :destroy
    has_many :categories, dependent: :destroy
    has_many :events, dependent: :destroy
    has_one :setting, class_name: "UserSetting", dependent: :destroy
    
    validates :name, 
        presence: true
    validates :email, 
        presence: true,
        format: { with: URI::MailTo::EMAIL_REGEXP, message: "Format must be 'algo@otracosa.algomas'. Instead recieved '%{value}'" },
        uniqueness: { case_sensitive: false }

end
