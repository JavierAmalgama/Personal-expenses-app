# rubocop:disable all
module Swagger
	def movement_definition
		{
			type: 'object',
			properties: {
				id: { type: :integer },
				kind: { type: :string, enum: [ "income", "expense" ] },
				date: { type: :string, format: :date },
				description: { type: :string },
				amount: { type: :string, example: "1500.50" },
				currency: { type: :string, example: "ARS" },
				category: { type: :string, nullable: true },
				subcategory: { type: :string, nullable: true },
				payment_method: {
					type: :string,
					nullable: true,
					enum: [ "cash", "debit_card", "credit_card", "transfer", "other", nil ]
				},
				credit_card: {
					type: :string,
					nullable: true,
					description: "Required when payment_method is credit_card, null otherwise",
					enum: [ "visa", "amex", "mercado_pago", "other", nil ]
				},
				beneficiary: { type: :string, nullable: true },
				notes: { type: :string, nullable: true },
				shared: { type: :boolean }
			}
		}
	end
end
