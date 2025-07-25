# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-07-23
# =========================================================

run 'clear'
include_auth = false

# =========================================================
# GEMS
# =========================================================
if yes?("Would you like to add Omniauth? (y/n):")
  include_auth = true
  gem "omniauth"
  gem "omniauth-rails_csrf_protection"
  gem "omniauth-entra-id"
end

gem "bundler-audit"
gem "lograge"

gem_group :development, :test do
  gem "dotenv-rails"
end

# =========================================================
# FILES
# =========================================================
remove_file('config/database.yml')
remove_file('config/credentials.yml.enc')
remove_file('config/master.key')

# https://anti-pattern.com/strip-leading-whitespace-from-heredocs-in-ruby

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

unless include_auth == false
  append_file '.env.development' do
    <<-CODE.strip_heredoc
    AUTH_PROVIDER_ID=123456
    AUTH_PROVIDER_SECRET=123456
    AUTH_PROVIDER_TENANT_ID=123456
    CODE
  end

  append_file '.env.development.local' do
    <<-CODE.strip_heredoc
    AUTH_PROVIDER_ID=123456
    AUTH_PROVIDER_SECRET=123456
    AUTH_PROVIDER_TENANT_ID=123456
    CODE
  end

  append_file '.env.test' do
    <<-CODE.strip_heredoc
    AUTH_PROVIDER_ID=123456
    AUTH_PROVIDER_SECRET=123456
    AUTH_PROVIDER_TENANT_ID=123456
    CODE
  end

  append_file '.env.test.local' do
    <<-CODE.strip_heredoc
    AUTH_PROVIDER_ID=123456
    AUTH_PROVIDER_SECRET=123456
    AUTH_PROVIDER_TENANT_ID=123456
    CODE
  end
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

after_bundle do
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
end

# =========================================================
# INITIALIZERS
# =========================================================

# YJIT
initializer 'enable_yjit.rb' do
  <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  RUBY
end
