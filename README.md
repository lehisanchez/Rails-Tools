# Rails Applications

My default workflow for starting a Ruby on Rails application.

## Requirements

Install the latest ruby version and set it as global using rbenv via brew. See [https://github.com/rbenv/](https://github.com/rbenv/rbenv).

### Install rust (for YJIT)

```shell
brew install rust
```

### Install rbenv

```shell
brew install ruby-build
```

### Install Ruby

```shell
rbenv init
RUBY_CONFIGURE_OPTS="--enable-yjit" rbenv install #{RUBY_VERSION}
rbenv global #{RUBY_VERSION}
rbenv rehash
```

Check the installation

```shell
ruby -v --yjit
```

You should see something like:

```shell
ruby 3.3.4 (2024-07-09 revision be1089c8ec) +YJIT [arm64-darwin23]
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
--asset-pipeline=propshaft

--skip-test
--skip-action-text
--skip-action-mailbox
--skip-decrypted-diffs

--devcontainer

--template=https://raw.githubusercontent.com/lehisanchez/Rails/main/template.rb
```

## Usage

```shell
rails new myapp
```

## What does this template do?

## Recommendations
