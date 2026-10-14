module Swagger
	def invalid_record_error_definition
		{
			type: 'object',
			properties: {
				error_name: { type: :string, enum: [ "invalid_record" ] },
				error_message: {
					type: :object,
					additionalProperties: {
						type: :array,
						items: { type: :string }
					}
				}
			}
		}
	end
end