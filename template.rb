# =========================================================
# Gems
# =========================================================
gem_group :development, :test do
  gem "faker", require: false
  gem "rspec-rails", require: false
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end

gem "devise"
gem "high_voltage"

# =========================================================
# RSpec
# =========================================================
after_bundle do
  rails_command("generate rspec:install")
end

# =========================================================
# Devise
# =========================================================
after_bundle do
  rails_command("generate devise:install")
end

environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'

# =========================================================
# High Voltage
# =========================================================
initializer 'high_voltage.rb', <<-CODE
  HighVoltage.configure do |config|
    config.home_page = "home"
    config.route_drawer = HighVoltage::RouteDrawers::Root
  end
CODE

file 'app/views/pages/home.html.erb'

# =========================================================
# Database
# =========================================================
after_bundle do
  # rails_command("db:drop")
  rails_command("db:create")
  rails_command("db:migrate")
  rails_command("db:seed")
end

# =========================================================
# GIT
# =========================================================
inject_into_file '.gitignore' do
  "\n# Hidden system files\n.DS_Store"
end

after_bundle do
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
