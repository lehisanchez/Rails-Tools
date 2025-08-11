# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-07-29
# =========================================================

# =========================================================
# QUESTIONS
# =========================================================
if yes?("Would you like to add authentication? (y/n):")
  skip_authentication = false
else
  skip_authentication = true
end

# =========================================================
# GEMS
# =========================================================
gem "bundler-audit"
gem "amazing_print"
gem "rails_semantic_logger"
gem "prefab-cloud-ruby"

gem_group :development, :test do
  gem "dotenv-rails"
end

gem_group :development do
  gem "rails_live_reload"
end

# =========================================================
# APPLICATION CONFIGURATION
# =========================================================
environment <<-RUBY
  config.generators do |generator|
    generator.assets false
    generator.helper false
    generator.stylesheets false
  end
RUBY

# =========================================================
# ROUTES
# =========================================================

# =========================================================
# MODELS
# =========================================================

# =========================================================
# FILES
# =========================================================
remove_file('config/database.yml')
remove_file('config/credentials.yml.enc')
remove_file('config/master.key')
remove_file('README.md')

# https://anti-pattern.com/strip-leading-whitespace-from-heredocs-in-ruby

# =========================================================
# .ENV FILES
# =========================================================
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

# =========================================================
# AUTHENTICATION .ENV FILES
# =========================================================
unless skip_authentication
  append_file '.env.development' do
    <<-CODE.strip_heredoc
    AUTH_CLIENT_ID=123456
    AUTH_CLIENT_SECRET=123456
    AUTH_TENANT_ID=123456
    CODE
  end

  append_file '.env.test' do
    <<-CODE.strip_heredoc
    AUTH_CLIENT_ID=123456
    AUTH_CLIENT_SECRET=123456
    AUTH_TENANT_ID=123456
    CODE
  end
end

# =========================================================
# BIN FILES
# =========================================================
file 'bin/ci' do
  <<-'RUBY'.strip_heredoc
  #!/usr/bin/env bash

  set -e

  if [ "${1}" = -h ]     || \
    [ "${1}" = --help ] || \
    [ "${1}" = help ]; then
    echo "Usage: ${0}"
    echo
    echo "Runs all tests, quality, and security checks"
    exit
  else
    if [ ! -z "${1}" ]; then
      echo "Unknown argument: '${1}'"
      exit 1
    fi
  fi

  echo "[ bin/ci ] Running unit tests"
  bin/rails test

  echo "[ bin/ci ] Running system tests"
  bin/rails test:system

  echo "[ bin/ci ] Analyzing code for security vulnerabilities."
  echo "[ bin/ci ] Output will be in tmp/brakeman.html, which"
  echo "[ bin/ci ] can be opened in your browser."
  bundle exec brakeman -q -o tmp/brakeman.html

  echo "[ bin/ci ] Analyzing Ruby gems for"
  echo "[ bin/ci ] security vulnerabilities"
  bundle exec bundle audit check --update

  echo "[ bin/ci ] Done"
  RUBY
end

file 'README.md' do
  <<-CODE.strip_heredoc
  # #{app_name.capitalize}

  ## Setup

  1. Pull down the app from version control
  2. Create .env files with database and client secrets

  ```bash
  echo "DATABASE_URL=postgres://postgres:postgres@${DB_HOST}:5432/#{app_name.downcase}_development" > .env.development
  ```

  ```bash
  echo "DATABASE_URL=postgres://postgres:postgres@${DB_HOST}:5432/#{app_name.downcase}_test" > .env.test
  ```

  ```bash
  echo 'DB_HOST="localhost"' > .env.development.local
  ```

  ```bash
  echo 'DB_HOST="localhost"' > .env.test.local
  ```

  3. Make sure you have Postgres installed and running
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

# ===========================
# .GITIGNORE
# ===========================
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

# =========================================================
# AUTHENTICATION
# =========================================================
unless skip_authentication
  gem "omniauth"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-entra-id"

  route "get \"/auth/:provider/callback\" => \"sessions/omni_auths#create\", as: :omniauth_callback"
  route "get \"/auth/failure\" => \"sessions/omni_auths#failure\", as: :omniauth_failure"

  file 'app/controllers/sessions/omni_auths_controller.rb' do
    <<-'RUBY'.strip_heredoc
    class Sessions::OmniAuthsController < ApplicationController
      allow_unauthenticated_access only: [ :create, :failure ]

      def create
        auth = request.env["omniauth.auth"]
        uid = auth["uid"]
        provider = auth["provider"]
        redirect_path = request.env["omniauth.params"]&.dig("origin") || root_path

        identity = OmniAuthIdentity.find_by(uid: uid, provider: provider)
        if authenticated?
          # User is signed in so they are trying to link an identity with their account
          if identity.nil?
            # No identity was found, create a new one for this user
            OmniAuthIdentity.create(uid: uid, provider: provider, user: Current.user)
            # Give the user model the option to update itself with the new information
            Current.user.signed_in_with_oauth(auth)
            redirect_to redirect_path, notice: "Account linked!"
          else
            # Identity was found, nothing to do
            # Check relation to current user
            if Current.user == identity.user
              redirect_to redirect_path, notice: "Already linked that account!"
            else
              # The identity is not associated with the current_user, illegal state
              redirect_to redirect_path, notice: "Account mismatch, try signing out first!"
            end
          end
        else
          # Check if identity was found i.e. user has visited the site before
          if identity.nil?
            # New identity visiting the site, we are linking to an existing User or creating a new one
            user = User.find_by(email_address: auth.info.email) || User.create_from_oauth(auth)
            identity = OmniAuthIdentity.create(uid: uid, provider: provider, user: user)
          end
          start_new_session_for identity.user
          redirect_to redirect_path, notice: "Signed in!"
        end
      end

      def failure
        redirect_to new_session_path, alert: "Authentication failed, please try again."
      end
    end
    RUBY
  end

  after_bundle do
    rails_command("generate authentication")
    rails_command("generate model OmniAuthIdentity uid:string provider:string user:references")
    rails_command("generate migration AddSourceToSessions source:string")
  end
end

# =========================================================
# INITIALIZERS
# =========================================================

# config/initializers/dotenv.rb
initializer 'dotenv.rb' do
  <<-'RUBY'.strip_heredoc
  Dotenv.require_keys("DATABASE_URL", "DB_HOST")
  RUBY
end

# config/initializers/enable_yjit.rb
initializer 'enable_yjit.rb' do
  <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  RUBY
end

# config/initializers/logging.rb
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

# config/initializers/omniauth_providers.rb
unless skip_authentication
  initializer 'omniauth_providers.rb' do
    <<-'RUBY'.strip_heredoc
    Rails.application.config.middleware.use OmniAuth::Builder do
      provider :developer if Rails.env.development? || Rails.env.test?
      provider(
        :entra_id,
        {
          client_id:      ENV['ENTRA_CLIENT_ID'],
          client_secret:  ENV['ENTRA_CLIENT_SECRET'],
          tenant_id:      ENV['ENTRA_TENANT_ID']
        }
      )
    end
    RUBY
  end
end

# =======================================================
# APP SETTINGS
# =======================================================

after_bundle do
  # rails_command("generate rspec:install") unless skip_rspec
  run("bundle install")
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
end
