class ApiError < StandardError
    attr_reader :code, :status, :details

    def initialize(message, code:, status:, details: {})
        super(message)
        @code = code
        @status = status
        @details = details
    end
end
