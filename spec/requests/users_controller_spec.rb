require "swagger_helper"

RSpec.describe UsersController, type: :request do
    path "/users" do
        get "Get all users" do
            security [ token_header: [] ]
            description "Returns all saved users"
            tags "Users"
            
            response 200, "Success" do
                include_context "with valid token"
                schema raw_collection_schema(:user)
                it "responds with all users" do
                    send_request
                    expect_collection_response(User.all)
                end
            end

            include_examples "requires authorization"
        end

        post "Create user" do
            security [ token_header: [] ]
            description "Creates new user"
            tags "Users"

            parameter name: :user_params, in: :body, schema: {
                type: :object,
                properties: {
                    name: { type: :string },
                    email: { type: :string }
                },
                required: %i[name email]
            }

            let(:name) { "My name" }
            let(:email) { "my_email@email.com" }
            let(:user_params) { {
                name: name,
                email: email
            } }

            response 201, "User created" do
                include_context "with valid token"
                schema raw_object_schema(:user)

                let(:created_user) { User.last }

                it "responds with created user" do
                    send_request
                    expect_object_response(created_user)
                end

                it "assigns attributes correctly" do
                    send_request
                    expect(created_user).to have_attributes(name: name, email: email)
                end
            end

            response 422, "Invalid user" do
                include_context "with valid token"
                schema error_response_schema

                let(:email) { "not-an-email" }

                before { token }

                it "doesn't create the user" do
                    expect { send_request }.not_to change(User, :count)
                    expect(response_error["code"]).to eq "validation_failed"
                    expect(response_error["details"].keys).to eq [ "email" ]
                end
            end

            include_examples "requires authorization"
        end
    end

    path "/users/{id}" do
        get "Get specific user" do
            security [ token_header: [] ]
            description "Returns a specific user"
            tags "Users"

            parameter name: :id, in: :path, schema: { type: :integer }

            let(:required_user) { create :user }
            let(:id) { required_user.id }
            response 200, "Success" do
                include_context "with valid token"
                schema raw_object_schema(:user)

                it "responds with required user" do
                    send_request
                    expect_object_response(required_user)
                end
            end

            response 404, "User not found" do
                include_context "with valid token"
                schema error_response_schema

                let(:id) { token; invalid_id_for(User) }

                it "responds not found" do
                    send_request
                    expect_error_response("not_found", "User not found")
                end
            end

            include_examples "requires authorization"
        end
    end
end
