# Rails Default Template

My default template for generating new Rails applications.

## Requirements

### Ruby

Install the latest ruby version and set it as global.

I install rbenv through homebrew:

```shell
brew install ruby-build
```

then run if needed:

```shell
  rbenv init
  rbenv install # LATEST RUBY e.g 3.3.4
  rbenv global # LATEST RUBY e.g 3.3.4
  rbenv rehash
```

### Gems

Create a .gemrc file in your $HOME (e.g. ~/.gemrc)

```shell
touch ~/.gemrc
```

```yaml
gem: --no-document
:backtrace: true
```

The update the gem system

```shell
  gem update --system
```

Install the latest Bundler and Rails

```shell
  gem install bundler rails
```

## Rails Config File (.railsrc)

```shell
touch ~/.railsrc
```

Add the following to ~/.railsrc

```yaml
--database=postgresql
--css=tailwind
--skip-action-mailbox
--skip-action-text
--skip-docker
--skip-test
--skip-system-test
--template=https://raw.githubusercontent.com/lehisanchez/Rails/main/template.rb
```

## Usage

```shell
rails new myapp
```

## What does this template do?

## Recommendations
