require "rails_helper"

RSpec.describe "Error handling", type: :request do
    let(:token) { create :users_token }
    let(:headers) { { "Authorization" => token.token, "Content-Type" => "application/json" } }

    def response_error
        JSON.parse(response.body)["error"]
    end

    context "when the body is malformed JSON" do
        it "responds bad request" do
            post "/movements", params: '{ "amount": ', headers: headers

            expect(response).to have_http_status(:bad_request)
            expect(response_error).to eq(
                "code" => "malformed_json",
                "message" => "The request body is not valid JSON",
                "details" => {}
            )
        end
    end

    context "when an unexpected error happens" do
        before do
            allow_any_instance_of(MovementsController).to receive(:filtered_movements)
                .and_raise(RuntimeError, "secret internals")
        end

        it "responds internal error without leaking the message" do
            get "/movements", headers: headers

            expect(response).to have_http_status(:internal_server_error)
            expect(response_error).to eq(
                "code" => "internal_error",
                "message" => "Something went wrong",
                "details" => {}
            )
        end
    end
end
