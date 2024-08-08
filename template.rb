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
  gem "rspec-rails", require: false
end

after_bundle do
  rails_command("importmap:install")
  rails_command("turbo:install")
  rails_command("stimulus:install")
  rails_command("tailwindcss:install")
  rails_command("generate rspec:install")

  # Devise
  rails_command("generate devise:install")

  # inject_into_file 'config/environments/development.rb', before: "  end" do
  #   '# config.action_mailer.default_url_options = { host: "localhost", port: 3000 }'
  # end

  environment '# config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'


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
  file 'app/components/foo.rb', <<-CODE
    "#
  CODE

  # Git
  inject_into_file '.gitignore' do
    "\n# Hidden system files\n.DS_Store"
  end

  # git add: "."
  # git commit: "-a -m 'Initial commit'"

  run "code ."
  run "open http://localhost:3000"
  run "bin/dev"
end
