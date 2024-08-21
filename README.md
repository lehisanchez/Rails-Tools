# Ruby on Rails Development

My environment and workflow for Ruby on Rails application development.

## Software

- [Download Visual Studio Code](https://code.visualstudio.com/download)
- [Download GitKraken](https://www.gitkraken.com/download)
- [Download pgAdmin](https://www.pgadmin.org/download/)
- [Download Docker](https://www.docker.com/products/docker-desktop/)
- [Download MySQL Workbench](https://dev.mysql.com/downloads/workbench/)
- [Install Brew](https://brew.sh/)
- [Install Oh My Zsh](https://ohmyz.sh/)
- [Download Inconsolata for Powerline (font)](https://github.com/powerline/fonts/tree/master/Inconsolata)

## Environment

### Ruby

If we want to take advantage of YJIT in Ruby, we need to install Rust.

```bash
brew install rust
```

#### rbenv

```shell
brew install rbenv
```

```shell
rbenv init
```

#### Install Ruby 3.3.4 (or latest version)

```shell
RUBY_CONFIGURE_OPTS="--enable-yjit" rbenv install 3.3.4
```

#### Set the global Ruby

```shell
rbenv global 3.3.4
```

```shell
rbenv rehash
```

#### Check the installation

```shell
ruby -v --yjit
```

#### You should see:

```shell
ruby 3.3.4 (2024-07-09 revision be1089c8ec) +YJIT [arm64-darwin23]
```

### Ruby Environment

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

## Ruby on Rails

Create a Rails config file:

```shell
touch ~/.railsrc
```

Add the following to ~/.railsrc

```text
--database=postgresql
--css=tailwind
--asset-pipeline=propshaft

--skip-test
--skip-action-text
--skip-action-mailbox
--skip-decrypted-diffs

--devcontainer

--template=https://raw.githubusercontent.com/lehisanchez/Rails/main/template.rb
```

## Postgresql

```shell
brew install postgresql@16 libpq
```

```shell
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
```

```shell
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
```

## Usage

```shell
rails new myapp
```

# What does this template do?

This template customizes the `rails new MYAPP` command and gives the developer options to install and tweak the application settings.

## Add Gems

```Ruby
gem "devise", "~> 4.9"
gem "kamal"
gem "thruster"
gem "nanoid", "~> 2.0"
gem "image_processing", ">= 1.2"

gem_group :development, :test do
  gem "faker"
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 6.1.0"
end

gem_group :development do
  gem "rails_live_reload"
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

### Gems List

- Devise (Authentication)
- Kamal (Deployment)
- Thruster (HTTP)
- Nanoid (Shorter alternative to UUID)
- Image Processing (Image variation processing for Active Storage)
- Faker (Test Data/Fixtures)
- Factory Bot (Test Factories)
- RSpec (Testing Framework)
- Capybara (Testing Tool)
- Selenium Webdriver (Testing Tool)


## Initializer: Enable YJIT

Adds the following to an initializer file to enable YJIT.

```ruby
if defined? RubyVM::YJIT.enable
  Rails.application.config.after_initialize do
    RubyVM::YJIT.enable
  end
end
```

## Initializer: UUID

Sets the global default primary_key to UUID by creating an initializer file

```ruby
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

## Initializer: Time Formats

The app I'm currently working on relies on date formats. I didn't think it would hurt if I kept this in.

```ruby
# Jan 01, 2023
Date::DATE_FORMATS[:short] = "%b %d, %Y"

# Sunday, January 01, 2023
Date::DATE_FORMATS[:long] = "%A, %B %d, %Y"

# Jan 01, 2023 03:30 PM
Time::DATE_FORMATS[:short] = "%b %d, %Y %I:%M %p"

# Sunday, January 01, 2023 at 03:30 PM
Time::DATE_FORMATS[:long] = "%A, %B %d, %Y at %I:%M %p"

# Jan 01, 2023 at 03:30 PM
Time::DATE_FORMATS[:nice] = "%b %d, %Y at %I:%M %p"
```


## Recommendations
