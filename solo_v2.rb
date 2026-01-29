# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE SOLO v2
# Author: Lehi Sanchez
# Updated: 2026-01-29
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

inject_into_file "config/ci.rb", after: "step \"Style: Ruby\", \"bin/rubocop\"\n" do
  '  step "Style: RSpec", "bundle exec rspec"'
end

gsub_file 'bin/setup', "system! \"bin/rails db:reset\" if ARGV.include?(\"--reset\")",
<<-EOS.strip_heredoc
\tsystem! "bin/rails db:reset"
\tsystem! "bin/rails db:migrate"
\tsystem! "bin/rails db:seed"

\tputs '\n== Preparing test database =='
\tsystem!({ "RAILS_ENV" => "test" }, "bin/rails db:reset")
EOS

run("code bin/setup")

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

after_bundle do
  # rails_command("generate rails_live_reload:install")
  # rails_command("generate rspec:install")
  # gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'
  # run("bundle exec bin/setup --skip-server")
  # run("bundle exec bin/ci")
  # run("code .")
end
