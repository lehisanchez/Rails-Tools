# =========================================================
# TEMPLATE VARIABLES
# =========================================================
#
# This is where we ask the developer what tools to include
# in the Rails application. Tools like authentication gems
# or Active Storage, etc.

# =========================================================
# GEMS
# =========================================================
gem "devise", "~> 4.9"
gem "kamal"
gem "thruster"
gem "nanoid", "~> 2.0"
gem "image_processing", ">= 1.2"

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
# CREATE INITIALIZERS
# =========================================================

# YJIT
# =========================================================
initializer 'enable_yjit.rb' do <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  RUBY
end

# UUID
# =========================================================
initializer 'enable_uuid.rb' do <<-'RUBY'.strip_heredoc
  Rails.application.config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
  RUBY
end

# Time Formats
# =========================================================
initializer 'time_formats.rb' do <<-'RUBY'.strip_heredoc
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
  RUBY
end

# =========================================================
# Active Storage
# =========================================================
after_bundle do
  run 'clear'
  if yes?("Would you like to install Active Storage? (y/n):")
    rails_command("active_storage:install")
  end
end

# =======================================================
# APP SETTINGS
# =======================================================

after_bundle do
  # =====================================================
  # ENVIRONMENT
  # =====================================================
  environment "config.generators.system_tests = nil" # Disables systems tests
  environment "config.generators.assets false" # Disables asset generation during 'rails g scaffold'
  environment "config.generators.helper false" # Disables helper
  environment "config.generators.stylesheets false" # Disables stylesheets

  # =====================================================
  # Apply RuboCop autocorrection to "rails g" files
  # =====================================================
  application(nil, env: "development") do <<-'RUBY'.strip_heredoc
    config.generators.after_generate do |files|
      parsable_files = files.filter { |file| File.exist?(file) && file.end_with?(".rb") }
      unless parsable_files.empty?
        system("bundle exec rubocop -A --fail-level=E #{parsable_files.shelljoin}", exception: true)
      end
    end
    RUBY
  end

  # =======================================================
  # DEFAULT URL OPTIONS
  # =======================================================
  append_file 'config/environments/development.rb' do
    "\nRails.application.routes.default_url_options = { host: \"localhost\", protocol: \"http\", port: 3000 }\n"
  end
end

# =========================================================
# Rubocop
# =========================================================
remove_file('.rubocop.yml')

file '.rubocop.yml' do <<-EOF.strip_heredoc
  inherit_gem: { rubocop-rails-omakase: rubocop.yml }

  Layout/SpaceInsideArrayLiteralBrackets:
    Enabled: false
  EOF
end

# =========================================================
# Factory Bot
# =========================================================
file 'spec/support/factory_bot.rb' do <<-'RUBY'.strip_heredoc
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
  RUBY
end

# =========================================================
# Nanoid
# =========================================================
file 'app/models/concerns/public_id_generator.rb' do <<-'RUBY'.strip_heredoc
  require "nanoid"

  module PublicIdGenerator
    extend ActiveSupport::Concern

    included do
      class_attribute :public_id_size
      self.public_id_size = PUBLIC_ID_LENGTH

      before_validation :set_public_id
    end

    PUBLIC_ID_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
    PUBLIC_ID_LENGTH = 12
    MAX_RETRY = 1000

    PUBLIC_ID_REGEX = /[\#{PUBLIC_ID_ALPHABET}]{\#{PUBLIC_ID_LENGTH}}\\z/

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
      self.class.generate_nanoid(alphabet: PUBLIC_ID_ALPHABET, size: self.public_id_size)
    end
  end
  RUBY
end

# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  # =======================================================
  # GEMFILE
  # =======================================================
  remove_file('Gemfile')
  remove_file('Gemfile.lock')

  file 'Gemfile' do <<-'RUBY'.strip_heredoc
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
    gem "image_processing", ">= 1.2"

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
    RUBY
  end

  run 'bundle install'

  # =========================================================
  # DATABASE
  # =========================================================

  inside 'config' do
    remove_file 'database.yml'

    create_file 'database.yml' do <<-CODE.strip_heredoc
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
    end
  end

  # =========================================================
  # README.md
  # =========================================================
  remove_file('README.md')

  file 'README.md' do <<-EOF.strip_heredoc
    # #{app_name.capitalize}
    EOF
  end

  # =========================================================
  # GIT
  # =========================================================
  append_file '.gitignore' do <<-EOF.strip_heredoc
    # Ignore hidden system files
    .DS_Store
    EOF
  end

  # =======================================================
  # INSTALLERS
  # =======================================================
  rails_command("generate rspec:install")
  rails_command("generate devise:install")

  # =======================================================
  # GENERATORS
  # =======================================================
  rails_command("generate controller Pages index --skip-routes")

  remove_file('app/views/pages/index.html.erb')

  file 'app/views/pages/index.html.erb' do <<-CODE.strip_heredoc
    <h1 class="text-4xl font-bold">#{app_name.capitalize}</h1>
    CODE
  end

  # =======================================================
  # ROUTES
  # =======================================================
  route 'root to: "pages#index"'

  # =======================================================
  # RSpec Root Test
  # =======================================================
  gsub_file 'spec/requests/pages_spec.rb', 'GET /index', 'GET /'
  gsub_file 'spec/requests/pages_spec.rb', 'get "/pages/index"', 'get root_path'

  remove_file('spec/views/pages/index.html.tailwindcss_spec.rb')

  file 'spec/views/pages/index.html.erb_spec.rb' do <<-CODE.strip_heredoc
    require 'rails_helper'

    RSpec.describe "pages/index", type: :view do
      it "displays the header" do
        render
        expect(rendered).to match /#{app_name.capitalize}/
      end
    end
    CODE
  end

  # =======================================================
  # Enable UUID
  # =======================================================
  generate(:migration, "EnableUUID")

  # Edit UUID migration file
  inject_into_file Dir.glob("db/migrate/*_enable_uuid.rb").first, after: "def change\n" do <<-'RUBY'
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    RUBY
  end

  # =======================================================
  # Database
  # =======================================================
  rails_command("db:prepare")

  # =======================================================
  # Credentials
  # =======================================================

  run 'clear'

  puts <<-EOF.strip_heredoc
  =================================

  Add the following to credentials:

  db:
    database: YOUR_DATABASE
    username: YOUR_USERNAME
    password: YOUR_PASSWORD

  =================================

  EOF

  run 'EDITOR="code --wait" rails credentials:edit' if yes?("Would you like to do that now? (y/n)")

  # =======================================================
  # 1Password ~ Save master.key to 1Password
  # =======================================================
  # https://developer.1password.com/docs/cli/reference/

  # =======================================================
  # RUN RUBOCOP
  # =======================================================
  run 'bundle exec rubocop -a'
  run 'bundle exec rspec'

  # =======================================================
  # GIT
  # =======================================================
  if yes?("Are you ready for the initial commit? (y/n):")
    git :init
    git add: "."
    git commit: "-a -m 'Initial commit'"
  end

  # =======================================================
  # OPEN
  # =======================================================
  if yes?("Open the project in VS Code? (y/n):")
    run "code ."
  end
end
