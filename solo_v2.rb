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
  gem "rspec-rails", "~> 8.0.0"
end

gem_group :development do
  gem "rails_live_reload"
end

gem "amazing_print"
gem "rails_semantic_logger"

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

initializer 'enable_yjit.rb' do
  <<-'RUBY'.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  RUBY
end

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

def prepare_databases
  rails_command("db:create")
  rails_command("db:migrate")
end

def run_setup_and_ci
  run("bundle exec bin/setup --skip-server --reset")
  run("bundle exec bin/ci")
end

def install_rails_authentication
  rails_command("generate authentication")
end

after_bundle do
  install_rspec
  install_rails_live_reload
  install_rails_authentication
  prepare_databases
  run_setup_and_ci
  run("code .")
end
