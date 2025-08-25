# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-08-25
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
run("mv bin/setup bin/setup.sample")

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
# BIN FILES
# =========================================================
file 'bin/setup' do
  <<-'RUBY'.strip_heredoc
  #!/usr/bin/env ruby
  require "fileutils"

  APP_ROOT = File.expand_path("..", __dir__)

  def system!(*args)
    system(*args, exception: true)
  end

  def log(message)
    puts "[ bin/setup ] #{message}"
  end

  FileUtils.chdir APP_ROOT do
    # This script is a way to set up or update your development environment automatically.
    # This script is idempotent, so that you can run it at any time and get an expectable outcome.
    # Add necessary setup steps to this file.

    log "Installing gems"
    # Only do bundle install if the much-faster
    # bundle check indicates we need to
    system("bundle check") || system!("bundle install")

    log "Dropping & recreating the development database"
    # Note that the very first time this runs, db:reset
    # will fail, but this failure is fixed by
    # doing a db:migrate
    system! "bin/rails db:reset || bin/rails db:migrate"

    log "Dropping & recreating the test database"
    # Setting the RAILS_ENV explicitly to be sure
    # we actually reset the test database
    system!({ "RAILS_ENV" => "test" }, "bin/rails db:reset || bin/rails db:migrate")

    log "Removing old logs and tempfiles"
    system! "bin/rails log:clear tmp:clear"

    unless ARGV.include?("--skip-server")
      log "Starting development server"
      STDOUT.flush # flush the output before exec(2) so that it displays
      exec "bin/dev"
    end
  end

  RUBY
end

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
  # Gems
  # =========================================
  gem "omniauth"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-entra-id"

  # Routes
  # =========================================
  route "get \"/auth/:provider/callback\" => \"sessions/omni_auths#create\", as: :omniauth_callback"
  route "get \"/auth/failure\" => \"sessions/omni_auths#failure\", as: :omniauth_failure"

  # ENV Variables
  # =========================================
  append_file '.env.development' do
    <<-CODE.strip_heredoc
    ENTRA_CLIENT_ID=ENTRA_CLIENT_ID
    ENTRA_CLIENT_SECRET=ENTRA_CLIENT_SECRET
    ENTRA_TENANT_ID=ENTRA_TENANT_ID
    CODE
  end

  append_file '.env.test' do
    <<-CODE.strip_heredoc
    ENTRA_CLIENT_ID=ENTRA_CLIENT_ID
    ENTRA_CLIENT_SECRET=ENTRA_CLIENT_SECRET
    ENTRA_TENANT_ID=ENTRA_TENANT_ID
    CODE
  end

  # Initializers
  # =========================================
  # config/initializers/omniauth_providers.rb
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

# =========================================================
# INITIALIZERS
# =========================================================

# config/initializers/monkey_patch_activerecord.rb
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
end

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

# =======================================================
# APP SETTINGS
# =======================================================

after_bundle do
  # rails_command("generate rspec:install") unless skip_rspec
  run("bundle install")
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
  unless skip_authentication
    rails_command("generate authentication")
    rails_command("generate model OmniAuthIdentity uid:string provider:string user:references")
    rails_command("generate migration AddSourceToSessions source:string")
    rails_command("db:migrate")
    rails_command("generate controller StaticPages home dashboard")
    route "get \"dashboard\" => \"static_pages#dashboard\", as: :dashboard"
    route "root \"static_pages#home\""
    inject_into_file "app/controllers/static_pages_controller.rb", after: "class StaticPagesController < ApplicationController" do
      "\nallow_unauthenticated_access only: %i[ home ]\n"
    end
  end
end
