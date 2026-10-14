class User < ApplicationRecord
    has_many :tokens, class_name: "UsersToken"
    has_many :movements, dependent: :destroy
    
    validates :name, 
        presence: true
    validates :email, 
        presence: true,
        format: { with: URI::MailTo::EMAIL_REGEXP, message: "Format must be 'algo@otracosa.algomas'. Instead recieved '%{value}'" },
        uniqueness: { case_sensitive: false }

end
