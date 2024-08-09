gem_group :test do
  gem 'shoulda-matchers', '~> 6.0'
end

gem_group :development, :test do
  gem "rspec-rails", require: false
end

gem_group :development do
  gem "rubocop-rails-omakase", require: false
end

gem "devise"
gem "high_voltage"

after_bundle do
  # RSpec
  rails_command("generate rspec:install")

  # Devise
  rails_command("generate devise:install")

  # inject_into_file 'config/environments/development.rb', before: "  end" do
  #   '# config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'
  # end

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

  # run "code ."
  # run "open http://localhost:3000"
  # run "bin/dev"
end
