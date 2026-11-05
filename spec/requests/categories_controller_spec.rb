require "swagger_helper"

RSpec.describe CategoriesController, type: :request do
    path "/categories" do
        get "Get categories" do
            security [ token_header: [] ]
            description "Returns the logged user's categories and subcategories, ordered by name"
            tags "Categories"

            parameter name: :kind, in: :query, required: false, schema: { type: :string, enum: Category.kinds.keys }

            let(:kind) { nil }

            response 200, "Success" do
                include_context "with valid token"
                schema raw_collection_schema(:category)

                let(:user) { token.user }
                let!(:housing) { create :category, user: user, name: "Vivienda" }
                let!(:rent) { create :category, user: user, name: "Alquiler", parent: housing }
                let!(:salary) { create :category, user: user, name: "Sueldo", kind: "income" }
                let!(:other_user_category) { create :category, name: "Ajena" }

                context "without filters" do
                    it "responds with the user's categories ordered by name" do
                        send_request
                        expect_collection_response([ rent, salary, housing ])
                    end
                end

                context "filtering by kind" do
                    let(:kind) { "expense" }

                    it "responds with the categories of that kind" do
                        send_request
                        expect_collection_response([ rent, housing ])
                    end
                end
            end

            response 422, "Invalid filter" do
                include_context "with valid token"
                schema error_response_schema

                let(:kind) { "transfer" }

                it "responds with invalid parameter" do
                    send_request
                    expect_error_response("invalid_parameter", "kind must be one of: income, expense", { kind: "transfer" })
                end
            end

            include_examples "requires authorization"
        end
    end
end
