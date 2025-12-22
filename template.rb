# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-10-15
# =========================================================



# =========================================================
# CUSTOMIZATIONS
# =========================================================
SKIP_AUTHENTICATION         = yes?("Add authentication? (y/n):") ? false : true
SKIP_OMNIAUTH               = SKIP_AUTHENTICATION ? true : ( yes?("Would you like to add OmniAuth? (y/n):") ? false : true )
SELECTED_OMNIAUTH_PROVIDER  = SKIP_OMNIAUTH ? "google" : ask("Which OmniAuth provider would you like to use?:", default: "google", limited_to: %w[entra google github]).downcase
SELECTED_DATABASE           = options[:database]



# =========================================================
# ADD GEMS
# =========================================================
# gem "bundler-audit"
gem "amazing_print"
gem "rails_semantic_logger"
gem "prefab-cloud-ruby"
# gem "rainbow"

gem_group :development, :test do
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "rails_live_reload"
end

unless SKIP_OMNIAUTH
  gem "omniauth"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-entra-id"       unless SELECTED_OMNIAUTH_PROVIDER != "entra"
  gem "omniauth-google-oauth2"  unless SELECTED_OMNIAUTH_PROVIDER != "google"
  gem "omniauth-github"         unless SELECTED_OMNIAUTH_PROVIDER != "github"
end


# =========================================================
# ADD AUTHENTICATION
# =========================================================
def add_authentication
  # Generate necessary files
  rails_command("generate authentication")
  rails_command("generate controller StaticPages home dashboard --skip-routes")

  # Generate route
  route 'root "static_pages#home"'

  # Allow public access to Home page
  inject_into_file "app/controllers/static_pages_controller.rb", after: "class StaticPagesController < ApplicationController" do
    "\nallow_unauthenticated_access only: %i[ home ]\n"
  end

  rails_command("generate migration AddUsernameToSessions username:string")

  append_file 'db/seeds.rb' do
    <<-CODE.strip_heredoc
    User.create!(
      username: "swiftie",
      email_address: "swiftie@example.com",
      password: "password123", # Rails Auth will hash this automatically
      password_confirmation: "password123"
    )
    CODE
  end

  return if SKIP_OMNIAUTH

  rails_command("generate migration AddSourceToSessions source:string")
  rails_command("generate model OmniAuthIdentity uid:string provider:string user:references")

  route 'get "/auth/:provider/callback" => "sessions/omni_auths#create", as: :omniauth_callback'
  route 'get "/auth/failure" => "sessions/omni_auths#failure", as: :omniauth_failure'

  append_file '.env.development' do
    <<-CODE.strip_heredoc
    CLIENT_ID=CLIENT_ID
    CLIENT_SECRET=CLIENT_SECRET
    TENANT_ID=TENANT_ID # Only needed for Entra
    CODE
  end

  append_file '.env.test' do
    <<-CODE.strip_heredoc
    CLIENT_ID=CLIENT_ID
    CLIENT_SECRET=CLIENT_SECRET
    TENANT_ID=TENANT_ID # Only needed for Entra
    CODE
  end
end



# =========================================================
# MODIFY FILES
# =========================================================
def remove_files
  remove_file('README.md')
  remove_file('config/credentials.yml.enc')
  remove_file('config/master.key')
  remove_file('config/database.yml') unless SELECTED_DATABASE == "sqlite3"
end



# =========================================================
# INSTALL RSpec
# =========================================================
def add_rspec
  # Install RSpec
  rails_command("generate rspec:install")

  # Modify Rails Helper file
  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'

  # Add Authentication Helpers
  file 'spec/support/authentication_helpers.rb' do
    <<-'RUBY'.strip_heredoc
    RSpec.shared_context "authentication helpers" do
      def sign_in_as(user)
        Current.session = user.sessions.create!

        ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
          cookie_jar.signed[:session_id] = Current.session.id
          cookies[:session_id] = cookie_jar[:session_id]
        end
      end

      def sign_out
        Current.session&.destroy!
        cookies.delete(:session_id)
      end
    end

    RSpec.configure { |config| config.include_context "authentication helpers" }
    RUBY
  end
end



# =========================================================
# Install Factory Bot
# =========================================================
def add_factory_bot
  file 'spec/support/factory_bot.rb' do
    <<-CODE.strip_heredoc
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
    CODE
  end
end

# =========================================================
# APPLICATION CONFIGURATION
# =========================================================
def add_configurations
  # config/application.rb
  # Disable generation of assets, helpers, and stylesheets
  # =========================================
  environment <<-RUBY
    config.generators do |generator|
      generator.assets false
      generator.helper false
      generator.stylesheets false
    end
  RUBY

  # Append to .gitignore
  # Ignore .env files and system files
  # =========================================
  append_file '.gitignore' do
    <<-CODE.strip_heredoc

    # The .env file is read for both dev and test
    # and creates more problems than it solves, so
    # we never ever want to use it
    .env

    # .env.*.local files are where we put actual
    # secrets we need for dev and test, so
    # we really don't want them in version control
    .env.*.local

    # Ignore hidden system files
    .DS_Store
    Thumbs.db
    CODE
  end



  # =========================================
  # Create .env files
  # =========================================
  run("touch .env.development .env.test .env.development.local .env.test.local")

  environment <<-RUBY
    Prefab.init
  RUBY

  file '.env.development' do
    <<-CODE.strip_heredoc
    PREFAB_DATASOURCES=LOCAL_ONLY
    CODE
  end

  # =========================================
  # Add Database Files
  # =========================================
  if SELECTED_DATABASE == "postegresql"
    file '.env.development' do
      <<-CODE.strip_heredoc
      DATABASE_URL=postgres://postgres:postgres@${DB_HOST}:5432/#{app_name.downcase}_development
      CODE
    end

    file '.env.test' do
      <<-CODE.strip_heredoc
      DATABASE_URL=postgres://postgres:postgres@${DB_HOST}:5432/#{app_name.downcase}_test
      CODE
    end

    file '.env.development.local' do
      <<-CODE.strip_heredoc
      DB_HOST="localhost"
      CODE
    end

    file '.env.test.local' do
      <<-CODE.strip_heredoc
      DB_HOST="localhost"
      CODE
    end
  end
end



# ====================================================
# Add Initializers
# ====================================================

def add_initializers
  # =========================================
  # config/initializers/omniauth_providers.rb
  # =========================================
  initializer 'omniauth_providers.rb' do
    <<-'RUBY'.strip_heredoc
    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :developer if Rails.env.development? || Rails.env.test?
      provider(
        :entra_id,
        {
          client_id:      ENV['CLIENT_ID'],
          client_secret:  ENV['CLIENT_SECRET'],
          tenant_id:      ENV['TENANT_ID']
        }
      )
    end
    RUBY
  end unless SKIP_OMNIAUTH


  # ================================================
  # config/initializers/monkey_patch_activerecord.rb
  # ================================================
  initializer 'monkey_patch_activerecord.rb' do
    <<-'RUBY'.strip_heredoc
    # The following is necessary to be able to drop a
    # PostgreSQL database that has active connections
    class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
      def drop
        establish_connection(public_schema_config)
        connection.execute "DROP DATABASE IF EXISTS \"#{db_config.database}\" WITH (FORCE)"
      end
    end
    RUBY
  end unless SELECTED_DATABASE != "postgresql"


  # =============================
  # config/initializers/dotenv.rb
  # =============================
  initializer 'dotenv.rb' do
    <<-'RUBY'.strip_heredoc
    Dotenv.require_keys("DATABASE_URL", "DB_HOST")
    RUBY
  end unless SELECTED_DATABASE == "sqlite3"


  # ==================================
  # config/initializers/enable_yjit.rb
  # ==================================
  initializer 'enable_yjit.rb' do
    <<-'RUBY'.strip_heredoc
    if defined? RubyVM::YJIT.enable
      Rails.application.config.after_initialize do
        RubyVM::YJIT.enable
      end
    end
    RUBY
  end


  # ==============================
  # config/initializers/logging.rb
  # ==============================
  initializer 'logging.rb' do
    <<-'RUBY'.strip_heredoc
    SemanticLogger.sync!                                  # Use synchronsous processing for targeting logging with current context
    SemanticLogger.default_level = :trace                 # Prefab will take over the filtering
    SemanticLogger.add_appender(
      io: $stdout,                                        # Use whatever appender you like
      formatter: Rails.env.development? ? :color : :json,
      filter: Prefab.log_filter,                          # Insert our Prefab filter
    )
    RUBY
  end
end



# =========================================================
# ADD SETUP FILE
# =========================================================
def add_setup
  # run("mv bin/setup bin/setup.sample")

  # file 'bin/setup' do
  #   <<-'RUBY'.strip_heredoc
  #   #!/usr/bin/env ruby
  #   require "fileutils"
  #   require "rainbow/refinement"

  #   using Rainbow

  #   APP_ROOT = File.expand_path("..", __dir__)

  #   def system!(*args)
  #     system(*args, exception: true)
  #   end

  #   FileUtils.chdir APP_ROOT do
  #     # This script is a way to set up or update your development environment automatically.
  #     # This script is idempotent, so that you can run it at any time and get an expectable outcome.
  #     # Add necessary setup steps to this file.
  #     puts "Installing gems".blue.bright
  #     # Only do bundle install if the much-faster
  #     # bundle check indicates we need to
  #     system("bundle check") || system!("bundle install")

  #     puts "Dropping & recreating the development database".blue.bright
  #     # Note that the very first time this runs, db:reset
  #     # will fail, but this failure is fixed by
  #     # doing a db:migrate
  #     system! "bin/rails db:reset || bin/rails db:migrate"

  #     puts "Dropping & recreating the test database".blue.bright
  #     # Setting the RAILS_ENV explicitly to be sure
  #     # we actually reset the test database
  #     system!({ "RAILS_ENV" => "test" }, "bin/rails db:reset || bin/rails db:migrate")

  #     puts "Removing old logs and tempfiles".blue.bright
  #     system! "bin/rails log:clear tmp:clear"

  #     puts "Done!".blue.bright
  #   end
  #   RUBY
  # end

  # run("chmod +x bin/setup")
end



# =========================================================
# ADD CI FILE
# =========================================================
def add_ci
  # run("mv bin/ci bin/ci.sample")
  # file 'bin/ci' do
  #   <<-CODE.strip_heredoc
  #   #!/usr/bin/env bash

  #   set -e

  #   echo "[ bin/ci ] Running RSpec tests"
  #   bundle exec rspec

  #   echo "[ bin/ci ] Analyzing code for security vulnerabilities."
  #   echo "[ bin/ci ] Output will be in tmp/brakeman.html, which"
  #   echo "[ bin/ci ] can be opened in your browser."
  #   bundle exec brakeman -q -o tmp/brakeman.html

  #   echo "[ bin/ci ] Analyzing Ruby Gems"
  #   bundle exec bundle audit check --update

  #   echo "[ bin/ci ] Done"
  #   CODE
  # end

  # run("chmod +x bin/ci")
end



# =========================================================
# ADD README FILE
# =========================================================
def add_readme
  file 'README.md' do
    <<-CODE.strip_heredoc
    # #{app_name.capitalize}

    ## Setup

    1. Pull down the app from version control
    2. Create .env files with database and client secrets
    3. Make sure you have #{SELECTED_DATABASE} installed and running
    4. Run `bin/setup` to install dependencies and set up the database
    5. Run `bin/ci` to run tests, quality, and security checks

    ## Running The Application

    1. Run `bin/dev` to start the application in development mode

    ## Tests and CI

    1. Run `bin/ci` to run all tests, quality, and security checks
    2. `tmp/test.log` will use production logging format *not* the development one.
    3. The vulnerability check output will be in `tmp/brakeman.html`, which can be opened in your browser

    ## Production

    * All runtime configuration should be supplied in the UNIX environment.
    * Rails logging uses Semantic Logging with Prefab.
    CODE
  end
end

# =======================================================
# AFTER BUNDLE
# =======================================================
after_bundle do
  remove_files
  add_configurations
  add_initializers
  add_rspec
  add_factory_bot
  add_authentication unless SKIP_AUTHENTICATION
  # add_setup
  # add_ci
  add_readme
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
end
