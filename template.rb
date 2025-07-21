# =========================================================
# RUBY ON RAILS APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2025-07-21
# =========================================================

# =========================================================
# GEMS
# =========================================================
gem_group :development do
  gem "dotenv-rails"
end

# =========================================================
# FILES
# =========================================================
remove_file('config/database.yml')
remove_file('config/credentials.yml.enc')
remove_file('config/master.key')
remove_file('bin/setup')

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
  #{"\n"}
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

file 'bin/setup' do
  <<-'RUBY'.strip_heredoc
  #!/usr/bin/env ruby

  require "optparse"

  def setup
    log "Installing gems"
    # Only do bundle install if the much-faster
    # bundle check indicates we need to
    system! "bundle check || bundle install"

    log "Dropping & recreating the development database"
    # Note that the very first time this runs, db:reset
    # will fail, but this failure is fixed by
    # doing a db:migrate
    system! "bin/rails db:reset || bin/rails db:migrate"

    log "Dropping & recreating the test database"
    # Setting the RAILS_ENV explicitly to be sure
    # we actually reset the test database
    system!({ "RAILS_ENV" => "test" }, "bin/rails db:reset")

    log "All set up."
    log ""
    log "To see commonly-needed commands, run:"
    log ""
    log "    bin/setup help"
    log ""
  end

  def help
    puts "Usage: #{$0}"
    puts ""
    puts "Installs gems, recreates dev database, and generally"
    puts "prepares the app to be run locally"
    puts ""
    puts "Other useful commands:"
    puts ""
    puts "  bin/dev"
    puts "     # run app locally"
    puts ""
    puts "  bin/ci"
    puts "     # runs all tests and checks as CI would"
    puts ""
    puts "  bin/rails test"
    puts "     # run non-system tests"
    puts ""
    puts "  bin/rails test:system"
    puts "     # run system tests"
    puts ""
    puts "  bin/setup help"
    puts "     # show this help"
    puts ""
  end

  # start of helpers

  # We don't want the setup method to have to do all this error
  # checking, and we also want to explicitly log what we are
  # executing. Thus, we use this method instead of Kernel#system
  def system!(*args)
    log "Executing #{args}"
    if system(*args)
      log "#{args} succeeded"
    else
      log "#{args} failed"
      abort
    end
  end

  # It's helpful to know what messages came from this
  # script, so we'll use log instead of `puts`
  def log(message)
    puts "[ bin/setup ] #{message}"
  end

  # end of helpers

  OptionParser.new do |parser|
    parser.on("-h", "--help") do
      help
      exit
    end
  end.parse!

  if ARGV[0] == "help"
    help
  elsif !ARGV[0].nil?
    puts "Unknown argument: '#{ARGV[0]}'"
    exit 1
  else
    setup
  end
  RUBY
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
