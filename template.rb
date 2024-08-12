# =========================================================
# GEMS
# =========================================================
gem "devise"

gem_group :development, :test do
  gem "rspec-rails"
end

# =========================================================
# INITIALIZERS
# =========================================================

# YJIT
initializer 'enable_yjit.rb', <<-CODE
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
CODE

# UUID
initializer 'enable_uuid.rb',  <<-CODE
  Rails.application.config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
CODE

# =========================================================
# GIT
# =========================================================
inject_into_file '.gitignore' do
  "\n# Hidden system files\n.DS_Store\n"
end

# =========================================================
# MISC
# =========================================================
remove_file('README.md')
create_file('README.md')

# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  # =======================================================
  # INSTALLERS
  # =======================================================
  rails_command("generate rspec:install")
  rails_command("generate devise:install")


  # =======================================================
  # APPLICATION SETTINGS
  # =======================================================
  environment "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }", env: "development"

  # =======================================================
  # GENERATORS
  # =======================================================
  rails_command("generate controller Pages index --skip-routes")

  # =======================================================
  # ROUTES
  # =======================================================
  route 'root to: "pages#index"'

  # =======================================================
  # Enable UUID
  # =======================================================
  generate(:migration, "EnableUUID")

  # Edit UUID migration file
  inject_into_file Dir.glob("db/migrate/*_enable_uuid.rb").first, after: "def change\n" do <<-CODE
    enable_extension 'pgcrypto'
  CODE
  end

  # =======================================================
  # Database
  # =======================================================
  rails_command("db:prepare")
end
