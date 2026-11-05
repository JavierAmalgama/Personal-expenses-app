class ApplicationController < ActionController::API
    include RenderingHelpers
    include ErrorHandling
    before_action :validate_token

    private

    def validate_token
        token = request.headers["Authorization"]
        raise UnauthorizedError.new("Authorization header is missing", code: :missing_token) unless token.present?

        @logged_user = get_user_from_token(token)
        raise UnauthorizedError.new("Token is invalid or expired", code: :invalid_token) if @logged_user.nil?
    end

    def get_user_from_token(token)
        users_token = UsersToken.find_by(token:token)
        if users_token!=nil && users_token.is_valid?
            return users_token.user
        end
    end
end
