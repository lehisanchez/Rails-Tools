# Rails Default Template

My default template for generating new Rails applications.

## Requirements

Install the latest ruby version and set it as global using rbenv via brew. See [https://github.com/rbenv/](https://github.com/rbenv/rbenv).

### Install rbenv

```shell
brew install ruby-build
```

### Install Ruby

```shell
rbenv init
rbenv install 3.3.0 #{OR_LATEST_RUBY_VERSION}
rbenv global 3.3.0 #{OR_LATEST_RUBY_VERSION}
rbenv rehash
```

### Configure Ruby Gems

Create a .gemrc file. See [https://guides.rubygems.org/](https://guides.rubygems.org/command-reference/#gem-environment).

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
