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

## Usage

```shell
rails new myapp
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

## What does this template do?

## Recommendations
