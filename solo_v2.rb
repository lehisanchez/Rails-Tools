# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE SOLO v2
# Author: Lehi Sanchez
# Updated: 2026-02-13
# =========================================================

# Template file has access to the following generator variables
# app_name
# database.name



# =========================================================
# CUSTOMIZATIONS
# =========================================================
@auth_question = 'Which auth provider?:'
SKIP_AUTHENTICATION = yes?("Add authentication? (y/n):") ? false : true
AUTH_PROVIDER = SKIP_AUTHENTICATION ? nil : ask(@auth_question, default: "", limited_to: %w[rails devise]).downcase


# =========================================================
# GEMS
# =========================================================
gem_group :development, :test do
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "faker"
  gem "foreman"
  gem "rails_live_reload"
  gem "ruby-lsp"
end

gem_group :test do
  gem "shoulda-matchers"
end

# Authentication
gem "devise", "~> 5.0" if AUTH_PROVIDER == 'devise'
gem "sqlite3", ">= 2.1" unless database.name == 'sqlite3'

# Logging
gem "amazing_print"
gem "rails_semantic_logger"

# Components
gem "view_component", "~> 4.3"



# =============================================================
# GIT
# =============================================================
# Append the following text to .gitignore

gitignore_text = <<-CODE.strip_heredoc
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

append_file '.gitignore', gitignore_text



# =============================================================
# ENVIRONMENT CONFIGURATION
# =============================================================
# Use the following environment variables

env_generators_config = <<-RUBY
  config.generators do |g|
    g.assets false
    g.helper false
    g.stylesheets false
    g.after_generate do |files|
      files.each do |file|
        next unless File.exist?(file)
        system("bundle exec rubocop -A --fail-level=A \#{file}")
      end
    end
  end
RUBY

# Generator Settings
environment env_generators_config, env: "development"

# Logging Settings
environment 'config.rails_semantic_logger.rendered   = false'
environment 'config.rails_semantic_logger.processing = false'
environment 'config.rails_semantic_logger.started    = false'
environment 'config.rails_semantic_logger.semantic   = false'

# Schema Format
environment 'config.active_record.schema_format = :sql'



# =============================================================
# INITIALIZERS
# =============================================================

# ================================================
# config/initializers/enable_yjit.rb
# ================================================
initializer 'enable_yjit.rb', <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  RUBY

# ================================================
# config/initializers/postgres.rb
# ================================================
if database.name == 'postgres'
  initializer 'monkey_patch_active_record.rb', <<-'RUBY'.strip_heredoc
  # The following is necessary to be able to drop a
  # PostgreSQL database that has active connections
  if Rails.env.development?
    class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
      def drop
        establish_connection(public_schema_config)
        connection.execute "DROP DATABASE IF EXISTS \"#{db_config.database}\" WITH (FORCE)"
      end
    end
  end
  RUBY
end


# =============================================================
# INSTALL LIVE RELOAD
# =============================================================
def install_rails_live_reload
  rails_command("generate rails_live_reload:install")
end



# =============================================================
# INSTALL RSPEC
# =============================================================
def install_rspec
  # RSpec Install
  rails_command("generate rspec:install")

  # Enable something...
  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'

  # Add RSpec test to bin/ci
  inject_into_file "config/ci.rb", after: "step \"Style: Ruby\", \"bin/rubocop\"\n" do
    '  step "Style: RSpec", "bundle exec rspec"'
  end

  # Add Shoulda Matchers to rspec helper file
  inject_into_file 'spec/rails_helper.rb' do
    <<-CODE.strip_heredoc
    Shoulda::Matchers.configure do |config|
      config.integrate do |with|
        with.test_framework :rspec
        with.library :rails
      end
    end
    CODE
  end

  # Add Authentication Helper
  file 'spec/support/authentication_helper.rb' do
    <<-CODE.strip_heredoc
    # spec/support/authentication_helper.rb

    module AuthenticationHelper
      def sign_in_as(user)
        session = user.sessions.create!(
          user_agent: "test",
          ip_address: "127.0.0.1"
        )

        # Use Rails' cookie signing mechanism
        key_generator = ActiveSupport::KeyGenerator.new(
          Rails.application.secret_key_base,
          iterations: 1000
        )
        secret = key_generator.generate_key("signed cookie")
        verifier = ActiveSupport::MessageVerifier.new(secret, serializer: JSON)
        signed_value = verifier.generate(session.id)

        cookies[:session_id] = signed_value
        session
      end
    end

    RSpec.configure do |config|
      config.include AuthenticationHelper, type: :request
    end
    CODE
  end unless SKIP_AUTHENTICATION
end



# =============================================================
# FACTORY BOT
# =============================================================
def install_factory_bot
  file 'spec/support/factory_bot.rb' do
    <<-CODE.strip_heredoc
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
    CODE
  end
end



# =============================================================
# DATABASES
# =============================================================
def prepare_databases(database)

  if database == "postgres"
    # Remove original database configuration
    remove_file('config/database.yml')

    file 'config/database.yml' do
      <<-CODE.strip_heredoc
      default: &postgresql
        adapter: postgresql
        encoding: unicode
        # For details on connection pooling, see Rails configuration guide
        # https://guides.rubyonrails.org/configuring.html#database-pooling
        max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
        <% if ENV["DB_HOST"] %>
        host: <%= ENV["DB_HOST"] %>
        username: postgres
        password: postgres
        <% end %>

      default: &sqlite
        adapter: sqlite3
        max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
        timeout: 5000

      development:
        <<: *postgresql
        database: #{app_name.downcase}_development

      test:
        <<: *postgresql
        database: #{app_name.downcase}_test

      production:
        primary: &primary_production
          url: <%= Rails.application.credentials.dig(:db, :url) %>
        cache:
          <<: *sqlite
          database: storage/production_cache.sqlite3
          migrations_paths: db/cache_migrate
        queue:
          <<: *sqlite
          database: storage/production_queue.sqlite3
          migrations_paths: db/queue_migrate
        cable:
          <<: *sqlite
          database: storage/production_cable.sqlite3
          migrations_paths: db/cable_migrate
      CODE
    end
  end

  rails_command("db:create")
  rails_command("db:migrate")
end



# =============================================================
# SETUP & CI
# =============================================================
def run_setup_and_ci
  run("bundle exec bin/setup --skip-server --reset")
  run("bundle exec bin/ci")
end



# =============================================================
# AUTHENTICATION
# =============================================================
def add_authentication

  # =======================================
  # Rails Authentication
  # =======================================
  if AUTH_PROVIDER == 'rails'
    rails_command("generate authentication")

    user_spec_file_path = 'spec/models/user_spec.rb'

    gsub_file user_spec_file_path, 'pending "add some examples to (or delete) #{__FILE__}"', ''

    inject_into_file user_spec_file_path, after: "RSpec.describe User, type: :model do\n" do
      <<-CODE.strip_heredoc
      describe 'validations' do
        subject { build(:user) }
        it { should be_valid }
      end
      CODE
    end

    run("bundle exec rubocop app spec #{user_spec_file_path} -a")
  end

  # =======================================
  # Devise Authentication
  # =======================================
  if AUTH_PROVIDER == 'devise'
    # Devise Install
    rails_command("generate devise:install")

    # Rubocop Devise Initializer
    run("bundle exec rubocop app spec config/initializers/devise.rb -a")

    # Enable support files
    gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'
  end
end



# =============================================================
# ADD PAGES
# =============================================================
def add_pages
  # Pages Controller
  rails_command("generate controller Pages home --skip-routes --no-view-specs --no-request-specs")

  # Allow unauthenticated access to home
  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n  # allow_unauthenticated_access only: %i[ home ]"
  end unless SKIP_AUTHENTICATION

  # remove home file
  remove_file('app/views/pages/home.html.erb')

  # create home file
  file 'app/views/pages/home.html.erb' do
    <<-CODE.strip_heredoc
    <h1 class="text-4xl font-bold">#{app_name.capitalize}</h1>
    CODE
  end

  # add route to home page
  route 'root to: "pages#home"'

  # Home View Spec
  file 'spec/views/pages/home.html.erb_spec.rb' do
    <<-CODE.strip_heredoc
    require 'rails_helper'

    RSpec.describe "pages/home", type: :view do
      it "displays the header" do
        render
        expect(rendered).to match /#{app_name.capitalize}/
      end
    end
    CODE
  end

  # Pages Request Spec
  file 'spec/requests/pages_spec.rb' do
    <<-'RUBY'.strip_heredoc
    require 'rails_helper'

    RSpec.describe "Pages", type: :request do
      describe "GET /" do
        it "returns http success" do
          get "/"
          expect(response).to have_http_status(:success)
        end
      end
    end
    RUBY
  end

  # allow unauthenticated access to home
  inject_into_file 'spec/requests/pages_spec.rb', after: "RSpec.describe \"Pages\", type: :request do\n" do
    <<-'RUBY'.strip_heredoc
    subject { create(:user) }

    before do
      sign_in_as(subject)
    end
    RUBY
  end unless AUTH_PROVIDER == 'devise'
end

# def install_devise
#   rails_command("generate devise:install")
#   run("bundle exec rubocop app spec config/initializers/devise.rb -a")
# end

def fix_devcontainer
  gsub_file '.devcontainer/compose.yaml', 'postgres-data:/var/lib/postgresql/data', 'postgres-data:/var/lib/postgresql'
  gsub_file '.devcontainer/compose.yaml', 'postgres:16.1', 'postgres:18.1'
  gsub_file 'Dockerfile', 'postgresql-client', 'postgresql-client sqlite3'
  gsub_file '.devcontainer/devcontainer.json', '"ghcr.io/rails/devcontainer/features/postgres-client": {}', '"ghcr.io/rails/devcontainer/features/postgres-client": {},'
  inject_into_file '.devcontainer/devcontainer.json', after: "\"ghcr.io/rails/devcontainer/features/postgres-client\": {},\n" do
    <<-CODE.strip_heredoc
    "ghcr.io/rails/devcontainer/features/sqlite3:1": {}
    CODE
  end
end

after_bundle do
  install_rspec
  install_factory_bot
  install_rails_live_reload
  add_authentication unless SKIP_AUTHENTICATION
  add_pages
  fix_devcontainer unless database.name != 'postgres'
  prepare_databases(database.name)
  run_setup_and_ci
  # run("code .devcontainer/devcontainer.json")
  run("code .")
end
