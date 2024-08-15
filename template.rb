# =========================================================
# GEMS
# =========================================================
# gem "devise", "~> 4.9"

# gem_group :development, :test do
#   gem "foreman", "~> 0.88.1"
#   gem "rspec-rails", "~> 6.1.0"
# end

# =========================================================
# INITIALIZERS
# =========================================================

# YJIT
initializer 'enable_yjit.rb', <<-CODE.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
CODE

# UUID
initializer 'enable_uuid.rb',  <<-CODE.strip_heredoc
  Rails.application.config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
CODE

# Time Formats
initializer 'time_formats.rb', <<-CODE.strip_heredoc
  # Jan 01, 2023
  Date::DATE_FORMATS[:short] = "%b %d, %Y"

  # Sunday, January 01, 2023
  Date::DATE_FORMATS[:long] = "%A, %B %d, %Y"

  # Jan 01, 2023 03:30 PM
  Time::DATE_FORMATS[:short] = "%b %d, %Y %I:%M %p"

  # Sunday, January 01, 2023 at 03:30 PM
  Time::DATE_FORMATS[:long] = "%A, %B %d, %Y at %I:%M %p"

  # Jan 01, 2023 at 03:30 PM
  Time::DATE_FORMATS[:nice] = "%b %d, %Y at %I:%M %p"
CODE

# =========================================================
# Rubocop
# =========================================================
remove_file('.rubocop.yml')

file '.rubocop.yml', <<-CODE.strip_heredoc
  inherit_gem: { rubocop-rails-omakase: rubocop.yml }

  Layout/SpaceInsideArrayLiteralBrackets:
    Enabled: false
CODE

# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  run 'clear'

  app_name = ask("What do you want to call your app?")

  # =========================================================
  # GEMFILE
  # =========================================================

  remove_file('Gemfile')
  remove_file('Gemfile.lock')

  file 'Gemfile', <<-CODE.strip_heredoc
    source "https://rubygems.org"

    gem "rails", "~> 7.2.0"

    # Front-End
    gem "propshaft"
    gem "importmap-rails"
    gem "turbo-rails"
    gem "stimulus-rails"
    gem "tailwindcss-rails"

    # Drivers
    gem "pg", "~> 1.1"
    gem "redis", ">= 4.0.1"

    # Deployment
    gem "puma", ">= 5.0"
    gem "thruster"
    gem "kamal"

    # Authentication
    gem "devise", "~> 4.9"

    # Other
    gem "jbuilder"
    gem "bootsnap", require: false
    gem "tzinfo-data", platforms: %i[ windows jruby ]


    group :development, :test do
      gem "brakeman", require: false
      gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
      gem "foreman", require: false
      gem "rspec-rails", "~> 6.1.0", require: false
      gem "rubocop-rails-omakase", require: false
    end

    group :development do
      gem "web-console"
    end

    group :test do
      gem "capybara"
      gem "selenium-webdriver"
    end
  CODE

  run 'bundle install'

  # =========================================================
  # DATABASE
  # =========================================================

  remove_file('config/database.yml')

  file 'config/database.yml', <<-CODE.strip_heredoc
    default: &default
      adapter: postgresql
      encoding: unicode
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      <% if ENV["DB_HOST"] %>
      host: <%= ENV["DB_HOST"] %>
      username: postgres
      password: postgres
      <% end %>

    development:
      <<: *default
      database: #{app_name.downcase}_development

    test:
      <<: *default
      database: #{app_name.downcase}_test

    production:
      <<: *default
      database: Rails.application.credentials.dig(:db, :database)
      username: Rails.application.credentials.dig(:db, :username)
      password: Rails.application.credentials.dig(:db, :password)
  CODE

  # =========================================================
  # README.md
  # =========================================================
  remove_file('README.md')

  file 'README.md', <<-CODE.strip_heredoc
    # #{app_name.capitalize}
  CODE

  # =========================================================
  # GIT
  # =========================================================
  inject_into_file '.gitignore' do <<-CODE.strip_heredoc
      # Hidden system files
      .DS_Store
    CODE
  end

  # =======================================================
  # INSTALLERS
  # =======================================================
  rails_command("generate rspec:install")
  rails_command("generate devise:install")

  # =======================================================
  # APPLICATION SETTINGS
  # =======================================================
  environment "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }", env: "development"
  environment 'config.active_record.record_timestamps = false'

  # =======================================================
  # GENERATORS
  # =======================================================
  rails_command("generate controller Pages index --skip-routes")

  # =======================================================
  # ROUTES
  # =======================================================
  route 'root to: "pages#index"'

  # =======================================================
  # Enable UUID
  # =======================================================
  generate(:migration, "EnableUUID")

  # Edit UUID migration file
  inject_into_file Dir.glob("db/migrate/*_enable_uuid.rb").first, after: "def change\n" do <<-CODE
    enable_extension 'pgcrypto'
  CODE
  end

  # =======================================================
  # Database
  # =======================================================
  rails_command("db:prepare")

  # =======================================================
  # Credentials
  # =======================================================
  run 'clear'

  puts <<-CODE.strip_heredoc
  =================================

  Add the following to credentials:

  db:
    database:
    username:
    password:

  =================================

  CODE

  run 'EDITOR="code --wait" rails credentials:edit' if yes?("Would you like to do that now? (y/n)")

  # =======================================================
  # GIT
  # =======================================================
  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"

  # =======================================================
  # 1Password ~ Save master.key to 1Password
  # =======================================================
  # https://developer.1password.com/docs/cli/reference/

  # =======================================================
  # OPEN
  # =======================================================

  run 'code .'
end
