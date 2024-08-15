source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", github: "rails/rails"

# Drivers
gem "pg", "~> 1.1"
gem "redis", ">= 4.0.1"

# Deployment
gem "puma", ">= 5.0"

# Front-end
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "high_voltage"

# Authentication
gem "devise"

# Other
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development do
  gem "web-console"
end

group :development, :test do
  gem "brakeman", require: false
  gem "debug"
  gem "faker", require: false
  gem "rspec-rails", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
