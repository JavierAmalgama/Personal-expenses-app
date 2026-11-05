class UnauthorizedError < ApiError
    def initialize(message, code:)
        super(message, code: code, status: :unauthorized)
    end
end
