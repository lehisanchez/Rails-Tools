# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE MINIMAL
# Author: Lehi Sanchez
# Updated: 2026-02-24
# =========================================================

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

# Databases
gem "sqlite_crypto" if database.name == 'sqlite3'



# =========================================================
# FILES & FOLDERS
# =========================================================

# ==========================
# GIT
# ==========================
append_file '.gitignore', "# Ignore hidden system files\n.DS_Store\nThumbs.db\n"

# ==========================
# DATABASES
# ==========================
remove_file('db/seeds.rb')
file 'db/seeds.rb', "require 'securerandom'\n"


# =========================================================
# ENVIRONMENT
# =========================================================

# Generators
environment <<-CODE.strip_heredoc

  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
    g.assets false
    g.helper false
    g.stylesheets false
  end

  CODE

# Schema Format
environment 'config.active_record.schema_format = :sql'



# =========================================================
# INITIALIZERS
# =========================================================

# ==================================
# config/initializers/enable_yjit.rb
# ==================================
initializer 'enable_yjit.rb', <<-CODE.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  CODE

# run("code config/initializers/enable_yjit.rb")



# =========================================================
# INSTALLERS
# =========================================================

# SQLite Encryption
def install_sqlite_encryption
  rails_command("generate sqlite_crypto:install")
end

# Rails Live Reload
def install_rails_live_reload
  rails_command("generate rails_live_reload:install")
end

# FactoryBot
def install_factory_bot
  file 'spec/support/factory_bot.rb' do
    <<-CODE.strip_heredoc
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
    CODE
  end
end

# RSpec
def install_rspec
  rails_command("generate rspec:install")

  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'

  inject_into_file "config/ci.rb", after: "step \"Style: Ruby\", \"bin/rubocop\"\n" do
    '  step "Style: RSpec", "bundle exec rspec"'
  end

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
          id: SecureRandom.uuid,
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
  end
end

# Authentication
def install_authentication
  rails_command("generate authentication")

  append_file 'db/seeds.rb' do
    <<-CODE.strip_heredoc

    User.find_or_create_by!(email_address: "admin@example.com") do |user|
      user.id = SecureRandom.uuid
      user.password = "example"
      user.password_confirmation = "example"
    end
    CODE
  end

  inject_into_file "spec/factories/users.rb", after: "factory :user do\n" do
    "    id { SecureRandom.uuid }\n"
  end
end



# Static Pages
def install_static_pages
  rails_command("generate controller Pages index --skip-routes --no-view-specs --no-request-specs")
  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n  allow_unauthenticated_access only: %i[ index ]"
  end
  remove_file('app/views/pages/index.html.erb')
  file 'app/views/pages/index.html.erb' do
    <<-CODE.strip_heredoc
    <h1 class="text-4xl font-bold">#{app_name.capitalize}</h1>
    CODE
  end
  route 'root to: "pages#index"'

  # RSpec Tests
  file 'spec/views/pages/home.html.erb_spec.rb' do
    <<-CODE.strip_heredoc
    require 'rails_helper'

    RSpec.describe "pages/index", type: :view do
      it "displays the header" do
        render
        expect(rendered).to match /#{app_name.capitalize}/
      end
    end
    CODE
  end

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
  end
end

# =========================================================
# DATABASES
# =========================================================
def prepare_databases
  rails_command("db:create")
  rails_command("db:migrate")
  rails_command("db:seed")
  rails_command("db:test:prepare")
end



# =============================================================
# SETUP & CI
# =============================================================
def run_setup_and_ci
  run("bundle exec bin/setup --skip-server --reset")
  run("bundle exec bin/ci")
end


# =============================================================
# GIT
# =============================================================
def commit
  git add: "."
  git commit: "-a -m 'Initial commit'"
end

# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  install_rails_live_reload
  install_rspec
  install_factory_bot
  install_sqlite_encryption
  install_authentication
  install_static_pages
  prepare_databases
  run_setup_and_ci
  commit
  run("code .")
end
