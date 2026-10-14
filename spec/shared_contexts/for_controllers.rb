RSpec.shared_context "with valid token" do
    let(:token) {create :users_token}
    let(:Authorization) { token.token }
end

RSpec.shared_context "with expired token" do
    let(:token) { create :users_token, valid_until: 1.minute.before }
    let(:Authorization) { token.token }
end