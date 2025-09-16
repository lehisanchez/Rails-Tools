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

If we want to take advantage of YJIT in Ruby, we need to install Rust.

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

### Install Ruby with YJIT enabled

```shell
RUBY_CONFIGURE_OPTS="--enable-yjit" rbenv install 3.4.6
```

```shell
rbenv global 3.4.6
```

```shell
rbenv rehash
```

### Check the installation

```shell
ruby -v --yjit
```

**You should see something like:**

```shell
ruby 3.4.5 (2025-05-14 revision a38531fd3f) +YJIT +PRISM
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
--devcontainer
--template=https://raw.githubusercontent.com/lehisanchez/Rails-Tools/main/template.rb
```

## Postgresql Environment

_For when using Postgresql_

```shell
brew install postgresql@16 libpq
```

```shell
echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
```

```shell
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
```

## Rails Application Environment

### Initializer: Enable YJIT

Adds the following to an initializer file to enable YJIT.

```ruby
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
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

### Initializer: Time Formats

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
