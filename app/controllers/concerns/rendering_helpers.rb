module RenderingHelpers
	def render_response(hash:, status:)
		render json: hash, adapter: :json, status: status
	end

	def render_successful_response(hash)
		render_response hash: hash, status: :ok
	end

	def render_object(object, options = {})
		render_successful_response object.serialize
		# render_successful_response ObjectRenderer.new(object, options).render
	end

	def render_collection(collection, options = {})
		render_successful_response collection.map(&:serialize)
		# render_successful_response CollectionRenderer.new(collection, options).render
	end

	def render_error(name:, message:, status:)
		hash = { response: { error_name: name, error_message: message } }
		render_response hash: hash, status: status
	end

	def render_empty_successful_response
		hash = { response: { status: "successful" } }
		render_successful_response hash
	end

	def render_app_error(exception)
		render_error(
			name: exception.name,
			message: exception.error_message,
			status: exception.status_code
		)
	end

	def render_invalid_parameter_error(exception)
		render_error(
			name: :invalid_parameter,
			message: "Parameter is missing or the value is empty: #{exception.param}",
			status: :bad_request
		)
	end

	def render_record_invalid_error(exception)
		render_error(
			name: :invalid_record,
			message: exception.record.errors.messages,
			status: :unprocessable_entity
		)
	end

	def render_record_not_found_error(exception)
		render_error(
			name: :record_not_found,
			message: "#{exception.model.constantize.model_name.human} not found",
			status: :not_found
		)
	end

	def render_invalid_argument_error(exception)
		render_error(
			name: :invalid_argument,
			message: exception.message,
			status: :unprocessable_entity
		)
	end

	def render_invalid_file_signature
		render_error(
			name: :invalid_file_signature,
			message: "The provided signed_id does not correspond to a valid blob",
			status: :unprocessable_entity
		)
	end

	def render_doorkeeper_token_expired_error
		render_error(
			name: :expired_access_token,
			message: "The provided access token has expired",
			status: :unauthorized
		)
	end

	def render_doorkeeper_token_revoked_error
		render_error(
			name: :revoked_access_token,
			message: "The provided access token has been revoked",
			status: :unauthorized
		)
	end

	def render_doorkeeper_token_unknown_error
		render_error(
			name: :invalid_access_token,
			message: "The provided access token is invalid",
			status: :unauthorized
		)
	end

	def render_doorkeeper_token_forbidden_error
		render_error(
			name: :forbidden_access_token,
			message: "You don't have permission to perform this action",
			status: :forbidden
		)
	end
end
