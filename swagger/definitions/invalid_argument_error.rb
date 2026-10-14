module Swagger
	def invalid_argument_error_definition
		{
			type: 'object',
			properties: {
				error_name: { type: :string, enum: [ "invalid_argument" ] },
				error_message: { type: :string }
			}
		}
	end
end