# Ruby on Rails Development

My environment and workflow for Ruby on Rails application development.

## Software & Tools

- [Download Visual Studio Code](https://code.visualstudio.com/download)
- [Download GitKraken](https://www.gitkraken.com/download)
- [Download pgAdmin](https://www.pgadmin.org/download/)
- [Download Docker](https://www.docker.com/products/docker-desktop/)
- [Install Brew](https://brew.sh/)
- [Install Oh My Zsh](https://ohmyz.sh/)
- [Download Inconsolata for Powerline (font)](https://github.com/powerline/fonts/tree/master/Inconsolata)

## Ruby

### Prerequisites

We need to install RBENV and RUST to manage our Ruby environments.

### Install Rust

```bash
brew install rust
```

### Install rbenv

```shell
brew install rbenv
```

```shell
rbenv init
```

### Install Ruby

```shell
RUBY_CONFIGURE_OPTS="--enable-zjit --enable-yjit" rbenv install 4.0.1
```

```shell
rbenv global 4.0.1
```

```shell
rbenv rehash
```

**Check the installation**

```shell
ruby -v --zjit
```

**You should see something like:**

```shell
ruby 4.0.1 (2026-01-13 revision e04267a14b) +ZJIT +PRISM [arm64-darwin24]
```



### Update Ruby Gem Environment

#### Configure .gemrc

Create a .gemrc file. See [https://guides.rubygems.org/](https://guides.rubygems.org/command-reference/#gem-environment).

```shell
touch ~/.gemrc
```

Paste in the following:

```text
gem: --no-document
:backtrace: true
```

Update the gem system.

```shell
gem update --system && gem update
```

### Install Bundler and Rails

```shell
gem install bundler rails
```

## Ruby on Rails Environment

Create a Rails config file:

```shell
touch ~/.railsrc
```

Add the following to ~/.railsrc

```shell
# =====================
# Configuration
# =====================
--edge
--devcontainer
--css=tailwind

# =====================
# Skips
# =====================

# --skip-solid
# --skip-action-cable
# --skip-action-mailer
--skip-action-mailbox
# --skip-action-text
# --skip-active-job
# --skip-active-record
# --skip-active-storage
# --skip-asset-pipeline
# --skip-ci
# --skip-git
# --skip-hotwire
# --skip-action-cable
# --skip-bootsnap
# --skip-brakeman
# --skip-bundler-audit
# --skip-dev-gems
# --skip-docker
# --skip-jbuilder
# --skip-kamal
# --skip-rubocop
# --skip-thruster
--skip-test
--skip-system-test

# =====================
# Template
# =====================
# --template=~/Code/Rails-Tools/solo_v2.rb
```

## Databases

### PostgreSQL
_For when using PostgreSQL_

```shell
brew install postgresql@18 libpq
```

```shell
echo 'export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"' >> ~/.zshrc
```

```shell
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
```

## Rails Application

### RSpec

Add the following to the application template:

```ruby
gem_group :development, :test do
  gem "factory_bot_rails"
  gem "faker", require: false
  gem "rspec-rails", "~> 8.0.0"
end
```

Install RSpec

```Ruby
def install_rspec
  rails_command("generate rspec:install")
  gsub_file 'spec/rails_helper.rb', '# Rails.root.glob', 'Rails.root.glob'
end
```

### Factory Bot

Add the following configuration to the RSpec support folder

```ruby
# spec/support/factory_bot.rb
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

### Initializers

#### Monkey Patch Active Record

The following will force drop PostgreSQL database tables even when there are active connections.

```ruby
# config/initializers/monkey_patch_activerecord.rb
# The following is necessary to be able to drop a
# PostgreSQL database that has active connections
class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
  def drop
    establish_connection(public_schema_config)
    connection.execute "DROP DATABASE IF EXISTS \"#{db_config.database}\" WITH (FORCE)"
  end
end
```

#### YJIT

Add the following initializer file to enable YJIT.

```ruby
# config/initializers/enable_yjit.rb
if defined? RubyVM::YJIT.enable
  Rails.application.config.after_initialize do
    RubyVM::YJIT.enable
  end
end
```

### Initializer: UUID

_For PostgreSQL_

Sets the global default primary_key to UUID by creating an initializer file

```ruby
# config/initializers/enable_uuid.rb
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

# Adjust .devcontainer Configuration

PostgreSQL applications need a few adjustments to the .devcontainer configuration.

- Bump image version to match local machine version
- Fix a known bug with volume storage

**PREVIOUS**
```yaml
# .devcontainer/compose.yaml
postgres:
  image: postgres:16.1 # <- bump this to match local version
  volumes:
    - postgres-data:/var/lib/postgresql/data # <- don't use data folder
```
**CURRENT**
```yaml
# .devcontainer/compose.yaml
postgres:
  image: postgres:18.1
  volumes:
    - postgres-data:/var/lib/postgresql
```
