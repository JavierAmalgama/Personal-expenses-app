# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'webmock/rspec'

WebMock.disable_net_connect!

require File.expand_path('../config/environment', __dir__)

RSpec.configure do |config|
	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
	end

	config.mock_with :rspec do |mocks|
		mocks.verify_partial_doubles = true
	end

	config.shared_context_metadata_behavior = :apply_to_host_groups
	RSpec::Matchers.define :have_same_ids do |expected|
		match do |actual|
			actual.collect(&:id) == expected.collect(&:id)
		end
	end
end
