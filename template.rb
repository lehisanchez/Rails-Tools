gem "devise"
gem "high_voltage"
gem "importmap-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

gem_group :development do
  gem "rubocop-rails-omakase", require: false
end

gem_group :test do
  gem "shoulda-matchers"
end

gem_group :development, :test do
  gem "rspec-rails"
end

after_bundle do
  rails_command("rails importmap:install")
  rails_command("rails turbo:install")
  rails_command("rails stimulus:install")
  rails_command("rails tailwindcss:install")
  rails_command("rails generate rspec:install")
  rails_command("rails generate devise:install")

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

  # Git
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"
end
