class InvalidParameterError < ApiError
    def initialize(message, details: {})
        super(message, code: :invalid_parameter, status: :unprocessable_entity, details: details)
    end
end
