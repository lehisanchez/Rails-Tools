# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE MINIMAL
# Author: Lehi Sanchez
# Updated: 2026-04-09
# =========================================================

# =========================================================
# GEMS
# =========================================================
gem_group :development do
  gem "foreman"
  gem "rails_live_reload"
  gem "ruby-lsp"
end

gem_group :test do
  gem "simplecov", require: false
end

gem "maquina-components"
gem "sqlite_crypto" if database.name == 'sqlite3'

# =========================================================
# FILES & FOLDERS
# =========================================================

# ==========================
# AGENT FILES
# ==========================
empty_directory ".claude"
create_file ".claude/CLAUDE.md"
create_file "AGENTS.md"
create_file "STYLES.md" do
  ""
end

get "https://raw.githubusercontent.com/basecamp/fizzy/7ef7a8e49b6143a43fcf9f413785767cc511ae12/STYLE.md", "STYLE.md"

# ==========================
# SimpleCov
# ==========================
prepend_to_file "test/test_helper.rb" do
  "require \"simplecov\"\nSimpleCov.start \"rails\"\n\n"
end

# ==========================
# GIT
# ==========================
append_file '.gitignore', "# Ignore hidden system files\n.DS_Store\nThumbs.db\n"
append_file '.gitignore', "# Ignore SimpleCov files\ncoverage\n"

# =========================================================
# ENVIRONMENT
# =========================================================

# Generators
environment <<-CODE.strip_heredoc
  # Enable UUIDs for primary keys
  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end

  CODE

# Schema Format
# environment 'config.active_record.schema_format = :sql'

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
end

# Static Pages
def install_static_pages
  rails_command("generate controller Pages index --skip-routes")
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
  install_sqlite_encryption
  install_authentication
  install_static_pages
  prepare_databases
  run_setup_and_ci
  commit
  run("code .")
end
