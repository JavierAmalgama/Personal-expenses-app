module Swagger
	def error_definition
		{
			type: 'object',
			properties: {
				code: { type: :string },
				message: { type: :string },
				details: { type: :object }
			},
			required: %i[code message details]
		}
	end
end
