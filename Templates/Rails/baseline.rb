# =========================================================
# RUBY ON RAILS BASELINE APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2026-05-16
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
# STATIC PAGES
# =========================================================
def install_static_pages
  rails_command("generate controller Pages welcome dashboard --skip-routes")

  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n  allow_unauthenticated_access only: %i[ welcome ]"
  end

  remove_file('app/views/pages/welcome.html.erb')

  file 'app/views/pages/welcome.html.erb' do
    <<-CODE.strip_heredoc
    <%= render "components/header" do %>
      <%= render "components/sidebar/trigger" %>
      <%= render "components/separator", orientation: :vertical %>
      <h1 class="text-sm font-medium">#{app_name.capitalize}</h1>
    <% end %>
    CODE
  end

  route 'root to: "pages#welcome"'
end


# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  rails_command("generate rails_live_reload:install")
  rails_command("generate sqlite_crypto:install")
  rails_command("generate maquina_components:install")
  rails_command("generate authentication")
  install_static_pages
  run("bundle exec bin/setup --skip-server --reset")
  run("bundle exec bin/ci")
  git add: "."
  git commit: "-a -m 'Initial commit'"
  run("code .")
end
