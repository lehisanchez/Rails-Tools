# =========================================================
# Gems
# =========================================================
gem_group :development, :test do
  gem "rspec-rails", require: false
end

gem_group :test do
  gem "shoulda-matchers"
end

gem "devise"
gem "high_voltage"

# =========================================================
# README
# =========================================================
run 'rm README.md'

# =========================================================
# Enable UUID
# =========================================================
after_bundle do
  generate(:migration, "EnableUUID")

  inject_into_file Dir.glob("db/migrate/*_enable_uuid.rb").first, after: "def change\n" do <<-CODE
    enable_extension 'pgcrypto'
  CODE
  end
end

inject_into_file 'config/application.rb', after: "config.eager_load_paths << Rails.root.join(\"extras\")\n" do <<-CODE
  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
CODE
end

# =========================================================
# RSpec
# =========================================================
after_bundle do
  rails_command("generate rspec:install")

  file 'spec/controllers/pages_controller_spec.rb', <<-CODE
  require 'rails_helper'

  describe HighVoltage::PagesController, '#show' do
    %w[home].each do |page|
      context "on GET to /\#{page}" do
        before do
          get :show, params: { id: page }
        end

        it { should respond_with(:success) }
      end
    end
  end
  CODE

end

# =========================================================
# Shoulda Matchers
# =========================================================
after_bundle do
  inject_into_file 'spec/rails_helper.rb' do <<-CODE

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
CODE
  end
end


# =========================================================
# Devise
# =========================================================
after_bundle do
  rails_command("generate devise:install")
  rails_command("generate devise User")
  rails_command("generate devise Admin")
end

# =========================================================
# High Voltage
# =========================================================
initializer 'high_voltage.rb', <<-CODE
  HighVoltage.configure do |config|
    config.home_page = "home"
    config.route_drawer = HighVoltage::RouteDrawers::Root
  end
CODE

file 'app/views/pages/home.html.erb'

# =========================================================
# YJIT
# =========================================================
initializer 'enable_yjit.rb', <<-CODE
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
CODE

# =========================================================
# Database
# =========================================================
after_bundle do
  rails_command("db:drop")
  rails_command("db:create")
  rails_command("db:migrate")
  rails_command("db:seed")
end

# =========================================================
# GIT
# =========================================================
inject_into_file '.gitignore' do
  "\n# Hidden system files\n.DS_Store\n"
end

after_bundle do
  # git add: "."
  # git commit: %Q( -m 'Initial commit' )
end
