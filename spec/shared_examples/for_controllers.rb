RSpec.shared_examples "requires authorization" do
    response 401, "Unauthorized" do
        schema error_response_schema

        context "without token" do
            let(:Authorization) { "" }

            it "responds missing token" do
                send_request
                expect_error_response("missing_token", "Authorization header is missing")
            end
        end

        context "with expired token" do
            include_context "with expired token"

            it "responds invalid token" do
                send_request
                expect_error_response("invalid_token", "Token is invalid or expired")
            end
        end

        context "with unknown token" do
            let(:Authorization) { "not-a-real-token-1" }

            it "responds invalid token" do
                send_request
                expect_error_response("invalid_token", "Token is invalid or expired")
            end
        end
    end
end
