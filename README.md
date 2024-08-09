# Rails Default Template

My default template for generating new Rails applications.

## Requirements

Install the latest ruby version and set it as global using rbenv via brew.

### Install rbenv

```shell
brew install ruby-build
```

### Install Ruby

```shell
rbenv init
rbenv install # LATEST RUBY e.g 3.3.4
rbenv global # LATEST RUBY e.g 3.3.4
rbenv rehash
```

### Configure Ruby Gems

Create a .gemrc file in your $HOME (e.g. ~/.gemrc)

```shell
touch ~/.gemrc
```

Then add the following:

```yaml
gem: --no-document
:backtrace: true
```

Then update the gem system:

```shell
  gem update --system
```

Install the latest Bundler and Rails:

```shell
  gem install bundler rails
```

## Rails Config File (.railsrc)

Create a Rails config file:

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
