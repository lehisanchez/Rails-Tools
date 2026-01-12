# Ruby on Rails Development

My environment and workflow for Ruby on Rails application development.

## Software & Tools

- [Download Visual Studio Code](https://code.visualstudio.com/download)
- [Download GitKraken](https://www.gitkraken.com/download)
- [Download pgAdmin](https://www.pgadmin.org/download/)
- [Download Docker](https://www.docker.com/products/docker-desktop/)
- [Download MySQL Workbench](https://dev.mysql.com/downloads/workbench/)
- [Install Brew](https://brew.sh/)
- [Install Oh My Zsh](https://ohmyz.sh/)
- [Download Inconsolata for Powerline (font)](https://github.com/powerline/fonts/tree/master/Inconsolata)

## Ruby Environment

### Prerequisites

If we want to take advantage of ZJIT in Ruby 4, we need to install Rust.

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

## Installing Ruby

### Install Ruby 4 with ZJIT Enabled

```shell
RUBY_CONFIGURE_OPTS="--enable-zjit" rbenv install 4.0.0
```

```shell
rbenv global 4.0.0
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
ruby 4.0.0 (2025-12-25 revision 553f1675f3) +ZJIT +PRISM
```

### Install Ruby 3.4.8 with YJIT Enabled

```shell
RUBY_CONFIGURE_OPTS="--enable-yjit" rbenv install 3.4.8
```

```shell
rbenv global 3.4.8
```

```shell
rbenv rehash
```

**Check the installation**

```shell
ruby -v --yjit
```

**You should see something like:**

```shell
ruby 3.4.8 (2025-12-17 revision 995b59f666) +YJIT +PRISM [arm64-darwin25]
```

## Ruby Gem Environment

### Configure .gemrc

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
gem update --system
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

```text
--css=tailwind
--edge
--devcontainer
--template=https://raw.githubusercontent.com/lehisanchez/Rails-Tools/main/template.rb
```

## Database

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

### RSpec Testing

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
