# Delete default Gemfile
run 'mv Gemfile Gemfile.example'

# Create Gemfile
file 'Gemfile', <<-CODE
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
CODE

# Bundle install
run 'bundle install'

# RSpec
rails_command("generate rspec:install")

# Devise
rails_command("generate devise:install")

environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'

# High Voltage
file 'app/views/pages/home.html.erb', <<-CODE
  Hello World!
CODE

initializer 'high_voltage.rb', <<-CODE
  HighVoltage.configure do |config|
    config.home_page = "home"
    config.route_drawer = HighVoltage::RouteDrawers::Root
  end
CODE

# Rubocop
file '.rubocop.yml', <<-CODE
inherit_gem:
  rubocop-rails-omakase: rubocop.yml
CODE

# Readme
run "rm README.md"

file 'README.md', <<-CODE
  "# Hello World!"
CODE

# Database
rails_command("db:drop")
rails_command("db:create")
rails_command("db:migrate")
rails_command("db:seed")

# Git
inject_into_file '.gitignore' do
  "\n# Hidden system files\n.DS_Store"
end

git add: "."
git commit: "-a -m 'Initial commit'"

run "code ."
# run "open http://localhost:3000"
# run "bin/dev"
