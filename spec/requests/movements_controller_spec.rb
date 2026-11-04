require "swagger_helper"

RSpec.describe MovementsController, type: :request do
    movement_body_properties = {
        kind: { type: :string, enum: Movement.kinds.keys },
        date: { type: :string, format: :date },
        description: { type: :string },
        amount: { type: :number },
        currency: { type: :string, enum: Movement::SUPPORTED_CURRENCIES },
        category: { type: :string },
        subcategory: { type: :string },
        payment_method: { type: :string, enum: Movement.payment_methods.keys },
        credit_card: { type: :string, enum: Movement.credit_cards.keys },
        beneficiary: { type: :string },
        notes: { type: :string },
        shared: { type: :boolean }
    }

    path "/movements" do
        get "Get movements" do
            security [ token_header: [] ]
            description "Returns the logged user's movements, newest first. Filters can be combined."
            tags "Movements"

            parameter name: :month, in: :query, required: false, schema: { type: :string, example: "2026-10" }
            parameter name: :category, in: :query, required: false, schema: { type: :string }
            parameter name: :kind, in: :query, required: false, schema: { type: :string, enum: Movement.kinds.keys }

            let(:month) { nil }
            let(:category) { nil }
            let(:kind) { nil }

            response 200, "Success" do
                include_context "with valid token"
                schema raw_collection_schema(:movement)

                let(:user) { token.user }
                let!(:october_rent) { create :movement, user: user, date: Date.new(2026, 10, 5), category: "Alquiler" }
                let!(:october_salary) { create :movement, :income, user: user, date: Date.new(2026, 10, 1) }
                let!(:september_groceries) { create :movement, user: user, date: Date.new(2026, 9, 20) }
                let!(:other_user_movement) { create :movement, date: Date.new(2026, 10, 5) }

                context "without filters" do
                    it "responds with the user's movements ordered by date desc" do
                        send_request
                        expect_collection_response([ october_rent, october_salary, september_groceries ])
                    end
                end

                context "filtering by month" do
                    let(:month) { "2026-10" }

                    it "responds with the movements of that month" do
                        send_request
                        expect_collection_response([ october_rent, october_salary ])
                    end
                end

                context "filtering by category" do
                    let(:category) { "Alquiler" }

                    it "responds with the movements of that category" do
                        send_request
                        expect_collection_response([ october_rent ])
                    end
                end

                context "filtering by kind" do
                    let(:kind) { "income" }

                    it "responds with the movements of that kind" do
                        send_request
                        expect_collection_response([ october_salary ])
                    end
                end

                context "combining filters" do
                    let(:month) { "2026-10" }
                    let(:kind) { "expense" }

                    it "responds with the movements matching all filters" do
                        send_request
                        expect_collection_response([ october_rent ])
                    end
                end
            end

            response 422, "Invalid filter" do
                include_context "with valid token"
                schema error_response_schema

                context "when month has an invalid format" do
                    let(:month) { "octubre" }

                    it "responds with invalid parameter" do
                        send_request
                        expect_error_response("invalid_parameter", "month must have the format YYYY-MM", { month: "octubre" })
                    end
                end

                context "when kind is invalid" do
                    let(:kind) { "transfer" }

                    it "responds with invalid parameter" do
                        send_request
                        expect_error_response("invalid_parameter", "kind must be one of: income, expense", { kind: "transfer" })
                    end
                end
            end

            include_examples "requires authorization"
        end

        post "Create movement" do
            security [ token_header: [] ]
            description "Creates a movement for the logged user"
            tags "Movements"

            parameter name: :movement_params, in: :body, schema: {
                type: :object,
                properties: movement_body_properties,
                required: %i[kind date description amount]
            }

            let(:movement_params) { {
                kind: "expense",
                date: "2026-10-14",
                description: "Compra semanal",
                amount: 23450.75,
                currency: "ARS",
                category: "Supermercado",
                subcategory: "Almacén",
                payment_method: "credit_card",
                credit_card: "mercado_pago",
                beneficiary: "Coto",
                notes: "Con descuento",
                shared: true
            } }

            response 201, "Movement created" do
                include_context "with valid token"
                schema raw_object_schema(:movement)

                let(:created_movement) { Movement.last }

                it "responds with created movement" do
                    send_request
                    expect_object_response(created_movement)
                end

                it "assigns attributes correctly" do
                    send_request
                    expect(created_movement).to have_attributes(
                        user: token.user,
                        kind: "expense",
                        date: Date.new(2026, 10, 14),
                        description: "Compra semanal",
                        amount: BigDecimal("23450.75"),
                        currency: "ARS",
                        category: "Supermercado",
                        subcategory: "Almacén",
                        payment_method: "credit_card",
                        credit_card: "mercado_pago",
                        beneficiary: "Coto",
                        notes: "Con descuento",
                        shared: true
                    )
                end
            end

            response 422, "Invalid movement" do
                include_context "with valid token"
                schema error_response_schema

                context "with several invalid fields" do
                    let(:movement_params) { { kind: "gift", amount: -10 } }

                    it "doesn't create the movement" do
                        expect { send_request }.not_to change(Movement, :count)
                        expect(response_error["code"]).to eq "validation_failed"
                        expect(response_error["details"].keys).to include("kind", "date", "description", "amount")
                    end
                end

                context "with a negative amount" do
                    let(:movement_params) { super().merge(amount: -5) }

                    it "responds with the amount error" do
                        send_request
                        expect_error_response("validation_failed", "Validation failed: Amount must be greater than 0",
                            { amount: [ "must be greater than 0" ] })
                    end
                end

                context "without description" do
                    let(:movement_params) { super().except(:description) }

                    it "responds with the description error" do
                        send_request
                        expect_error_response("validation_failed", "Validation failed: Description can't be blank",
                            { description: [ "can't be blank" ] })
                    end
                end

                context "with an unsupported currency" do
                    let(:movement_params) { super().merge(currency: "EUR") }

                    it "responds with the currency error" do
                        send_request
                        expect_error_response("validation_failed", "Validation failed: Currency must be one of: ARS, USD",
                            { currency: [ "must be one of: ARS, USD" ] })
                    end
                end
            end

            include_examples "requires authorization"
        end
    end

    path "/movements/{id}" do
        parameter name: :id, in: :path, schema: { type: :integer }

        let(:owner) { create :user }
        let(:movement) { create :movement, user: owner }
        let(:id) { movement.id }

        shared_context "as the movement owner" do
            include_context "with valid token"
            let(:token) { create :users_token, user: owner }
        end

        shared_examples "not found movement" do
            response 404, "Movement not found" do
                include_context "as the movement owner"
                schema error_response_schema

                context "when it belongs to another user" do
                    let(:movement) { create :movement }

                    it "responds not found" do
                        send_request
                        expect_error_response("not_found", "Movement not found")
                    end
                end

                context "when it doesn't exist" do
                    let(:id) { invalid_id_for(Movement) }

                    it "responds not found" do
                        send_request
                        expect_error_response("not_found", "Movement not found")
                    end
                end
            end
        end

        get "Get specific movement" do
            security [ token_header: [] ]
            description "Returns a movement of the logged user"
            tags "Movements"

            response 200, "Success" do
                include_context "as the movement owner"
                schema raw_object_schema(:movement)

                it "responds with required movement" do
                    send_request
                    expect_object_response(movement)
                end
            end

            include_examples "not found movement"
            include_examples "requires authorization"
        end

        patch "Update movement" do
            security [ token_header: [] ]
            description "Updates a movement of the logged user"
            tags "Movements"

            parameter name: :movement_params, in: :body, schema: {
                type: :object,
                properties: movement_body_properties
            }

            let(:movement_params) { { description: "Nueva descripción", amount: 99.9, shared: true } }

            response 200, "Movement updated" do
                include_context "as the movement owner"
                schema raw_object_schema(:movement)

                it "responds with updated movement" do
                    send_request
                    expect_object_response(movement.reload)
                end

                it "updates only the given attributes" do
                    send_request
                    expect(movement.reload).to have_attributes(
                        description: "Nueva descripción",
                        amount: BigDecimal("99.9"),
                        shared: true,
                        category: "Supermercado"
                    )
                end
            end

            response 422, "Invalid movement" do
                include_context "as the movement owner"
                schema error_response_schema

                let(:movement_params) { { amount: 0 } }

                it "doesn't update the movement" do
                    send_request
                    expect(movement.reload.amount).to eq BigDecimal("1500.50")
                end
            end

            include_examples "not found movement"
            include_examples "requires authorization"
        end

        delete "Delete movement" do
            security [ token_header: [] ]
            description "Deletes a movement of the logged user"
            tags "Movements"

            response 204, "Movement deleted" do
                include_context "as the movement owner"

                it "deletes the movement" do
                    send_request
                    expect(Movement.exists?(movement.id)).to eq false
                    expect_no_content_response
                end
            end

            include_examples "not found movement"
            include_examples "requires authorization"
        end
    end
end
