# rubocop:disable all
module Swagger
	def category_definition
		{
			type: 'object',
			properties: {
				id: { type: :integer },
				name: { type: :string },
				kind: { type: :string, enum: [ "income", "expense" ] },
				parent_id: { type: :integer, nullable: true, description: "Id of the root category when this is a subcategory" }
			}
		}
	end
end
