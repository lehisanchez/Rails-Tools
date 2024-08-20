# =========================================================
# GEMS
# =========================================================
gem "devise", "~> 4.9"
gem "kamal"
gem "thruster"
gem "nanoid", "~> 2.0"

gem_group :development, :test do
  gem "faker"
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 6.1.0"
end

gem_group :development do
  gem "rails_live_reload"
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

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
# Factory Bot
# =========================================================
file 'spec/support/factory_bot.rb', <<-CODE.strip_heredoc
  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
  end
CODE

# =========================================================
# Nanoid
# =========================================================
file 'app/models/concerns/public_id_generator.rb', <<-CODE.strip_heredoc
  require "nanoid"

  module PublicIdGenerator
    extend ActiveSupport::Concern

    included do
      before_create :set_public_id
    end

    PUBLIC_ID_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
    PUBLIC_ID_LENGTH = 12
    MAX_RETRY = 1000

    PUBLIC_ID_REGEX = /[#{PUBLIC_ID_ALPHABET}]{#{PUBLIC_ID_LENGTH}}\z/

    class_methods do
      def generate_nanoid(alphabet: PUBLIC_ID_ALPHABET, size: PUBLIC_ID_LENGTH)
        Nanoid.generate(size: size, alphabet: alphabet)
      end
    end

    # Generates a random string for us as the public ID.
    def set_public_id
      return if public_id.present?
      MAX_RETRY.times do
        self.public_id = generate_public_id
        return unless self.class.where(public_id: public_id).exists?
      end
      raise "Failed to generate a unique public id after \#{MAX_RETRY} attempts"
    end

    def generate_public_id
      self.class.generate_nanoid(alphabet: PUBLIC_ID_ALPHABET)
    end
  end
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
    gem "bootsnap"
    gem "tzinfo-data", platforms: %i[ windows jruby ]
    gem "nanoid", "~> 2.0"

    group :development, :test do
      gem "brakeman"
      gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
      gem "faker"
      gem "factory_bot_rails"
      gem "rspec-rails", "~> 6.1.0"
      gem "rubocop-rails-omakase"
    end

    group :development do
      gem "rails_live_reload"
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
      \n
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
  environment "config.active_record.record_timestamps = false" # Disables automatic timestamps
  environment "config.generators.system_tests = nil" # Disables systems tests
  environment "config.generators.assets false" # Disables asset generation during 'rails g scaffold'
  environment "config.generators.helper false" # Disables helper
  environment "config.generators.stylesheets false" # Disables stylesheets

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
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
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
    database: #{app_name.downcase}
    username: postgres
    password: postgres

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
