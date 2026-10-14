class ApplicationController < ActionController::API
    include RenderingHelpers
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found_error
    rescue_from ArgumentError, with: :render_invalid_argument_error
    before_action :validate_token

    private

    def validate_token
        token = request.headers["Authorization"]
        return head :unauthorized unless token.present?
            
        @logged_user = get_user_from_token(token)
        return head :forbidden if @logged_user == nil
    end

    def get_user_from_token(token)
        users_token = UsersToken.find_by(token:token)
        if users_token!=nil && users_token.is_valid?
            return users_token.user
        end
    end
end
