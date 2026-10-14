source "https://rubygems.org"

ruby "3.1.4"

gem "rails", "~> 7.1.3", ">= 7.1.3.2"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

gem "pg"
gem "active_model_serializers"
gem "rack-cors"
gem "rswag"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "dotenv-rails", "~> 2.7.6"
  gem "bullet"
end

group :development do
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 6.0"
  gem "webmock"
end
