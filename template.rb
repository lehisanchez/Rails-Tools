# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-07-23
# =========================================================

# =========================================================
# GEMS
# =========================================================
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

file '.env.test' do
  <<-CODE.strip_heredoc
  DATABASE_URL=postgres://postgres:postgres@postgres:5432/#{app_name.downcase}_test
  CODE
end

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
