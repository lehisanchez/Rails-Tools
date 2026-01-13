# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2026-01-12
# =========================================================

# =========================================================
# GEMS
# =========================================================
gem_group :development, :test do
  gem "sqlite"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker", require: false
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "rails_live_reload"
end

# =========================================================
# INSTALL RSpec
# =========================================================
def add_rspec
  rails_command("generate rspec:install")
  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'
end

# =========================================================
# INSTALL Rails Live Reload
# =========================================================
def add_rails_live_reload
  rails_command("generate rails_live_reload:install")
end

def add_configurations
  run("touch .env.development .env.test .env.development.local .env.test.local")

  # Update CI with RSpec
  inject_into_file "config/ci.rb", after: "step \"Style: Ruby\", \"bin/rubocop\"\n" do
    '  step "Style: RSpec", "bundle exec rspec"'
  end

  # Environment
  environment 'config.active_record.schema_format = :sql'

  # Disable generators
  environment <<-RUBY
    config.generators do |generator|
      generator.assets false
      generator.helper false
      generator.stylesheets false
    end
  RUBY

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
end

# =========================================================
# Initializers
# =========================================================

# ==================================
# Enable YJIT
# ==================================
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

after_bundle do
  add_rspec
  add_rails_live_reload
  add_configurations
  run("bundle exec bin/setup --skip-server")
  run("bundle exec bin/ci")
  run("code .")
end
