# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-07-23
# =========================================================

run 'clear'

# =========================================================
# QUESTIONS
# =========================================================
if yes?("Would you like to add Omniauth? (y/n):")
  skip_authentication = false
else
  skip_authentication = true
end

# =========================================================
# GEMS
# =========================================================

unless skip_authentication
  gem "omniauth"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-entra-id"
end

gem "bundler-audit"
gem "amazing_print"
gem "rails_semantic_logger"
gem "prefab-cloud-ruby"

gem_group :development, :test do
  gem "dotenv-rails"
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "rails_live_reload"
end

# =========================================================
# FILES
# =========================================================
remove_file('config/database.yml')
remove_file('config/credentials.yml.enc')
remove_file('config/master.key')
remove_file('readme.md')

# https://anti-pattern.com/strip-leading-whitespace-from-heredocs-in-ruby

# =========================================================
# .ENV FILES
# =========================================================
file '.aprc' do
  <<-'RUBY'.strip_heredoc
  AwesomePrint.defaults = {
    :indent => -2,
    :color => {
      :hash  => :pale,
      :class => :white
    }
  }
  RUBY
end

file '.env.development' do
  <<-CODE.strip_heredoc
  DATABASE_URL=postgres://postgres:postgres@postgres:5432/#{app_name.downcase}_development
  CODE
end

file '.env.development.local' do
  <<-CODE.strip_heredoc
  DATABASE_URL=postgres://postgres:postgres@localhost:5432/#{app_name.downcase}_development
  CODE
end

file '.env.test' do
  <<-CODE.strip_heredoc
  DATABASE_URL=postgres://postgres:postgres@postgres:5432/#{app_name.downcase}_test
  CODE
end

file '.env.test.local' do
  <<-CODE.strip_heredoc
  DATABASE_URL=postgres://postgres:postgres@localhost:5432/#{app_name.downcase}_test
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

  append_file '.env.development.local' do
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

  append_file '.env.test.local' do
    <<-CODE.strip_heredoc
    AUTH_CLIENT_ID=123456
    AUTH_CLIENT_SECRET=123456
    AUTH_TENANT_ID=123456
    CODE
  end
end

file 'README.md' do <<-EOF.strip_heredoc
  # #{app_name.capitalize}

  ## Setup

  1. Pull down the app from version control
  2. Make sure you have Postgres installed and running
  3. Run `bin/setup` to install dependencies and set up the database
  4. Run `bin/ci` to run tests, quality, and security checks

  ## Running The Application

  1. Run `bin/dev` to start the application in development mode

  ## Tests and CI

  1. Run `bin/ci` to run all tests, quality, and security checks
  2. `tmp/test.log` will use production logging format *not* the development one.
  3. The vulnerability check output will be in `tmp/brakeman.html`, which can be opened in your browser

  ## Production

  * All runtime configuration should be supplied in the UNIX environment.
  * Rails logging uses Semantic Logging with Prefab.
  EOF
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

  echo "[ bin/ci ] Running tests"
  bundle exec rspec

  echo "[ bin/ci ] Analyzing code for security vulnerabilities."
  echo "[ bin/ci ] Output will be in tmp/brakeman.html, which"
  echo "[ bin/ci ] can be opened in your browser."
  bundle exec brakeman -q -o tmp/brakeman.html

  echo "[ bin/ci ] Analyzing Ruby gems for"
  echo "[ bin/ci ] security vulnerabilities"
  bundle exec bundle audit check --update

  echo "[ bin/ci ] Analyzing code quality with RuboCop"
  bundle exec rubocop -a

  echo "[ bin/ci ] Done"
  RUBY
end

# =========================================================
# INITIALIZERS
# =========================================================

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
          client_id:      ENV['AUTH_CLIENT_ID'],
          client_secret:  ENV['AUTH_CLIENT_SECRET'],
          tenant_id:      ENV['AUTH_TENANT_ID']
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
  # ===========================
  # ENVIRONMENT CONFIGURATION
  # ===========================
  environment "config.generators.system_tests = nil"  # Disables systems tests
  environment "config.generators.assets false"        # Disables asset generation during 'rails g scaffold'
  environment "config.generators.helper false"        # Disables helper
  environment "config.generators.stylesheets false"   # Disables stylesheets

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
    CODE
  end

  # ===========================
  # INSTALLERS
  # ===========================
  rails_command("generate rspec:install")
  rails_command("generate authentication") unless skip_authentication
  run("bundle install")
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
end
