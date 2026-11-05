module Requests

	def response_properties(model)
		{ data: { '$ref': "#/components/schemas/#{model}" } }
	end

	def object_response_schema(model)
		{ type: :object, properties: response_properties(model), required: [:data] }
	end

	def send_request
		submit_request(self.class.metadata)
	end

	def expect_object_response(object)
		expect_response(object.serialize)
	end

	def expect_response(response_hash)
		expect_equivalent_json_strings(response.body, response_hash.to_json)
	end

	def expect_equivalent_json_strings(left_json, right_json)
		expect(JSON.parse(left_json)).to eq JSON.parse(right_json)
	end

	def collection_response_properties(model)
		{
			response: {
				type: 'array',
				items: { '$ref': "#/components/schemas/#{model}" }
			}
		}
	end

	def collection_response_schema(model)
		{ type: :object, properties: collection_response_properties(model), required: [ :response ] }
	end

	def raw_collection_schema(model)
		{
			type: 'array',
			items: { '$ref': "#/components/schemas/#{model}" }
		}
	end

	def raw_object_schema(model)
		{ '$ref': "#/components/schemas/#{model}" }
	end

	def error_response_schema
		{
			type: :object,
			properties: { error: { '$ref': '#/components/schemas/error' } },
			required: [:error]
		}
	end

	def expect_collection_response(collection)
		expect_response(collection.map(&:serialize))
	end

	def expect_no_content_response
		expect(response.body.blank?).to eq true
		expect(response).to have_http_status(:no_content)
	end

	def expect_error_response(code, message, details = {})
		expect_response(error: { code: code, message: message, details: details })
	end

	def response_error
		JSON.parse(response.body)["error"]
	end
end
