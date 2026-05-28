source "https://rubygems.org"

# Use specific branch of Rails
gem "rails", github: "rails/rails", branch: "8-1-stable"

# Assets & front end
gem "importmap-rails"
gem "maquina-components"
gem "propshaft"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

# Deployment and drivers
gem "bootsnap", require: false
gem "kamal", require: false
gem "puma", ">= 5.0"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "sqlite3", ">= 2.1"
gem "sqlite_crypto", "~> 2.2"
gem "thruster", require: false

# Features
gem "bcrypt", "~> 3.1.7"
gem "jbuilder"
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubycritic", require: false
end

group :development do
  gem "rails_live_reload"
  gem "ruby-lsp"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
end
