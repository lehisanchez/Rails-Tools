# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE SOLO v2
# Author: Lehi Sanchez
# Updated: 2026-01-30
# =========================================================



# =========================================================
# GEMS
# =========================================================
gem_group :development, :test do
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "rails_live_reload"
end

gem "amazing_print"
gem "rails_semantic_logger"



# =============================================================
# GIT IGNORE
# =============================================================
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


# =============================================================
# ENVIRONMENT CONFIGURATION
# =============================================================
environment <<-RUBY
  config.generators do |generator|
    generator.assets false
    generator.helper false
    generator.stylesheets false
  end
RUBY

environment 'config.rails_semantic_logger.rendered   = false'
environment 'config.rails_semantic_logger.processing = false'
environment 'config.rails_semantic_logger.started    = false'
environment 'config.rails_semantic_logger.semantic   = false'
environment 'config.active_record.schema_format = :sql'



# =============================================================
# INITIALIZERS
# =============================================================
initializer 'enable_yjit.rb' do
  <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
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

def install_rspec
  # RSpec Install
  rails_command("generate rspec:install")

  # Enable something...
  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'

  # Add RSpec test to bin/ci
  inject_into_file "config/ci.rb", after: "step \"Style: Ruby\", \"bin/rubocop\"\n" do
    '  step "Style: RSpec", "bundle exec rspec"'
  end
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
def prepare_databases
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
  rails_command("generate authentication")
end



# =============================================================
# PAGES
# =============================================================
def add_pages
  # generate pages controller
  rails_command("generate controller Pages home --skip-routes")

  # allow unauthenticated access to home
  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n\tallow_unauthenticated_access only: %i[ home ]"
  end

  # remove home file
  remove_file('app/views/pages/home.html.erb')

  # create home file
  file 'app/views/pages/home.html.erb' do <<-CODE.strip_heredoc
    <h1 class="text-4xl font-bold">#{app_name.capitalize}</h1>
    CODE
  end

  # add route to home page
  route 'root to: "pages#home"'

  # remove generated test file
  remove_file('spec/views/pages/home.html.tailwindcss_spec.rb')

  # create a new test file
  file 'spec/views/pages/home.html.erb_spec.rb' do <<-CODE.strip_heredoc
    require 'rails_helper'

    RSpec.describe "pages/home", type: :view do
      it "displays the header" do
        render
        expect(rendered).to match /#{app_name.capitalize}/
      end
    end
    CODE
  end

  # adjust request test file
  gsub_file 'spec/requests/pages_spec.rb', 'describe "GET /home" do', 'describe "GET /" do'
  gsub_file 'spec/requests/pages_spec.rb', 'get "/pages/home"', 'get "/"'
end

after_bundle do
  install_rspec
  install_factory_bot
  install_rails_live_reload
  add_authentication
  add_pages
  prepare_databases
  run_setup_and_ci
  run("code .")
end
