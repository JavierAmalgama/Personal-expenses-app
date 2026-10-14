RSpec.shared_examples "requires authorization" do
    response 401, "Unauthorized" do
        let(:Authorization) { "" }

        it "should respond unauthorized" do
            send_request
            expect_head_response(401)
        end
    end
    
    response 403, "Forbidden" do
        let(:token) { create :users_token, valid_until: 1.minute.before }
        let(:Authorization) { token.token }

        it "should respond forbidden" do
            send_request
            expect_head_response(403)
        end
    end
end