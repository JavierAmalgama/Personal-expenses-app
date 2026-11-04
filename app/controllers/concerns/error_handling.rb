module ErrorHandling
    extend ActiveSupport::Concern

    # rescue_from handlers are matched bottom-up, so the catch-all must stay first.
    included do
        rescue_from StandardError, with: :render_internal_error
        rescue_from ActionController::ParameterMissing, with: :render_parameter_missing_error
        rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_malformed_json_error
        rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found_error
        rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid_error
        rescue_from ApiError, with: :render_api_error
    end

    private

    def render_internal_error(exception)
        Rails.logger.error("#{exception.class}: #{exception.message}\n#{exception.backtrace&.join("\n")}")
        render_error code: :internal_error, message: "Something went wrong", status: :internal_server_error
    end

    def render_parameter_missing_error(exception)
        render_error code: :parameter_missing, message: "Parameter is missing or empty: #{exception.param}",
            status: :bad_request, details: { param: exception.param }
    end

    def render_malformed_json_error(_exception)
        render_error code: :malformed_json, message: "The request body is not valid JSON", status: :bad_request
    end

    def render_record_not_found_error(exception)
        model_name = exception.model&.constantize&.model_name&.human || "Record"
        render_error code: :not_found, message: "#{model_name} not found", status: :not_found
    end

    def render_record_invalid_error(exception)
        render_error code: :validation_failed, message: exception.message,
            status: :unprocessable_entity, details: exception.record.errors.messages
    end

    def render_api_error(exception)
        render_error code: exception.code, message: exception.message,
            status: exception.status, details: exception.details
    end
end
