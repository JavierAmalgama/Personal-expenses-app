
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
require 'shoulda/matchers'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec', 'shared_examples', '**', '*.rb')].sort.each { |f| require f }
Dir[Rails.root.join('spec', 'shared_contexts', '**', '*.rb')].sort.each { |f| require f }

Shoulda::Matchers.configure do |config|
	config.integrate do |with|
		with.test_framework :rspec
		with.library :rails
	end
end

begin
	ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
	puts e.to_s.strip
	exit 1
end
RSpec.configure do |config|
	# rubocop:disable all
	# Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
	config.include FactoryBot::Syntax::Methods
	config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
	config.use_transactional_fixtures = true
	# https://relishapp.com/rspec/rspec-rails/docs
	config.infer_spec_type_from_file_location!

	# Filter lines from Rails gems in backtraces.
	config.filter_rails_from_backtrace!
	# arbitrary gems may also be filtered via:
	# config.filter_gems_from_backtrace("gem name")
	config.extend Requests
	config.include Requests
	config.extend Blobs
	config.include Blobs
	config.include ActiveRecordHelper

	if Bullet.enable?
		config.before(:each) do
			Bullet.start_request
		end
		
		config.after(:each) do
			Bullet.perform_out_of_channel_notifications if Bullet.notification?
			Bullet.end_request
		end
	end	  
end
