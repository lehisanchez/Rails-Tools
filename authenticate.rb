#!/usr/bin/env ruby
require "fileutils"

APP_ROOT = File.expand_path("..", __dir__)

FileUtils.chdir APP_ROOT do
  puts "== Authenticating Rails App =="
  system("rails generate authenticate")

  # puts "\n== Copying sample files =="
  # unless File.exist?("config/database.yml")
  #   FileUtils.cp "config/database.yml.sample", "config/database.yml"
  # end

  # puts "\n== Preparing database =="
  # system! "bin/rails db:prepare"

  # puts "\n== Removing old logs and tempfiles =="
  # system! "bin/rails log:clear tmp:clear"

  # unless ARGV.include?("--skip-server")
  #   puts "\n== Starting development server =="
  #   STDOUT.flush # flush the output before exec(2) so that it displays
  #   exec "bin/dev"
  # end
end
