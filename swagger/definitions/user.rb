# rubocop:disable all
module Swagger
	def user_definition
		{
			type: 'object',
			properties: {
				id: { type: :integer },
				name: { type: :string },
				email: { type: :string }
			}
		}
	end
end
