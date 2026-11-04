module RenderingHelpers
	def render_response(hash:, status:)
		render json: hash, adapter: :json, status: status
	end

	def render_successful_response(hash)
		render_response hash: hash, status: :ok
	end

	def render_object(object, options = {})
		render_successful_response object.serialize
	end

	def render_created(object)
		render_response hash: object.serialize, status: :created
	end

	def render_collection(collection, options = {})
		render_successful_response collection.map(&:serialize)
	end

	def render_error(code:, message:, status:, details: {})
		render_response hash: { error: { code: code, message: message, details: details } }, status: status
	end
end
