# =========================================================
# RUBY ON RAILS BASELINE APPLICATION TEMPLATE
# Author: Lehi Sanchez
# Updated: 2026-05-16
# =========================================================

# =========================================================
# GEMFILE
# =========================================================
remove_file "Gemfile"

get "https://github.com/lehisanchez/Rails-Tools/raw/refs/heads/main/Templates/Rails/baseline_gemfile.rb", "Gemfile"


# =========================================================
# FILES & FOLDERS
# =========================================================

# ==========================
# AGENT FILES
# ==========================
empty_directory ".claude"

create_file ".claude/CLAUDE.md" do
  "@../AGENTS.md"
end

create_file "AGENTS.md" do
  <<-CODE.strip_heredoc
  # AGENTS.md

  Guidance for coding agents in this repo. Style rules live in `@STYLE.md` — read it before non-trivial work.

  ## Development Commands

  ### Setup and Server
  ```bash
  bin/setup              # First-time setup: bundle install, db:prepare, clear logs/tmp
  bin/dev                # Start dev server via foreman (web + Tailwind CSS watcher)
  ```

  Development URL: http://localhost:3000

  ### Testing
  ```bash
  bin/rails test                               # Run full test suite (parallelized Minitest)
  bin/rails test test/models/user_test.rb      # Run a single test file
  bin/rails test test/models/user_test.rb:42   # Run a single test by line number
  bin/rails test:system                        # Run system tests (Capybara + Selenium)
  bin/ci                                       # Run full CI suite (style, security, tests)
  env RAILS_ENV=test bin/rails db:seed:replant # Verifies seeds load cleanly (CI runs this).

  # For parallel test execution issues, use:
  PARALLEL_WORKERS=1 bin/rails test
  ```

  CI pipeline — `bin/ci` is a thin wrapper that runs the step list in `config/ci.rb`, which uses Rails 8.1's `ActiveSupport::ContinuousIntegration` DSL. Steps, in order:
  1. Setup (`bin/setup --skip-server`)
  2. Rubocop (style)
  3. Bundler audit (gem security)
  4. Importmap audit
  5. Brakeman (security scan)
  6. Application tests (`bin/rails test`)
  7. Seeds load check (`env RAILS_ENV=test bin/rails db:seed:replant`)

  System tests are defined but commented out in `config/ci.rb` — they do **not** run in CI by default.

  ### Database
  ```bash
  bin/rails db:fixtures:load   # Load fixture data
  bin/rails db:migrate          # Run migrations
  bin/rails db:prepare   # Create and migrate the database
  bin/rails db:reset            # Drop, create, and load schema
  ```

  ### Other Utilities
  ```bash
  bin/jobs               # Manage Solid Queue jobs
  bin/kamal deploy       # Deploy (requires 1Password CLI for secrets)
  bin/rails server       # Start Puma on port 3000 (without CSS watcher)
  bin/rails console      # Rails REPL
  bin/rubocop            # Lint Ruby code (RuboCop Rails Omakase)
  bin/brakeman           # Static security analysis
  bin/bundler-audit      # Audit gems for known vulnerabilities
  ```

  ## Stack

  - Ruby 4
  - Rails 8.1 (`8-1-stable` from GitHub)
  - SQLite everywhere — primary DB plus Solid Queue/Cache/Cable, each in its own file under `storage/`
  - Propshaft + Import Maps + Tailwind
  - Hotwire (Turbo + Stimulus) with `maquina-components`
  - Minitest + Capybara/Selenium
  - Kamal + Thruster + Puma for deploy.

  Solid Queue runs in-Puma via `SOLID_QUEUE_IN_PUMA`. Schemas for the Solid trio are in `db/{queue,cache,cable}_schema.rb`, separate from `db/schema.rb`. Active Storage is local disk (`config/storage.yml`). PWA stubs exist in `app/views/pwa/` but routes are commented out.

  ## Authentication

  Custom session-based auth (no Devise). Three pieces:

  - `app/controllers/concerns/authentication.rb` — included in `ApplicationController`; adds a global `before_action :require_authentication`. Opt out per-controller with `allow_unauthenticated_access`. Session lookup is by signed `:session_id` cookie. Post-login redirects to stashed `session[:return_to_after_authenticating]`.
  - `app/models/current.rb` — `CurrentAttributes` holding the active `Session`.
  - `User has_secure_password` + `has_many :sessions`; email normalized (strip + downcase) on assignment.

  **New controllers are authenticated by default — public endpoints must explicitly call `allow_unauthenticated_access`.**

  ### UUID Primary Keys

  All tables use UUID primary keys (`primary_key_type: :uuid`), generated as UUIDv7 (time-sortable) via the `sqlite_crypto` gem — see `config/initializers/sqlite_crypto.rb`. Because v7 IDs are time-ordered, `.first`/`.last` reflect insertion order.

  ### Background Jobs (Solid Queue)

  Database-backed job queue (no Redis):
  - Solid Queue, Solid Cache, and Solid Cable all run on SQLite — no Redis or other broker is required.
  - `ApplicationJob` is the stock Rails default — no custom ActiveJob extensions.
  - Recurring/scheduled jobs are configured in `config/recurring.yml`.

  ### Frontend

  Hotwire (Turbo + Stimulus) — no heavy JS framework. Use Turbo Frames and Turbo Streams for partial page updates. Use Stimulus sparingly for behavior that can't be handled by Turbo.

  UI components come from the `maquina-components` gem. Prefer composing existing Maquina components in views over hand-rolling new markup. `https://maquina.app/documentation/components/`

  Utilize the Maquina UI Standards skill to build consistent, accessible UIs in Rails using maquina_components. Reference `https://maquina.app/documentation/ai-tools/maquina-ui-standards/` for guidance.

  ## Agent Behavior

  - **Never** use `bin/rails generate` — write files by hand to stay intentional.
  - **Never** add a service object unless explicitly asked; prefer rich models.
  - **Always** run `bin/rubocop -a` after editing Ruby files.
  - **Always** run relevant tests before declaring a task done.
  - **Never** modify `db/schema.rb` directly — only via migrations.
  - When adding a route, prefer a new resource over a custom action.
  - Ask before creating new abstractions or files not directly needed.
  - **Verify** the spec-driven-development plugin is available before planning or building a feature; if it's missing, prompt the user to install it (see [Spec-Driven Development (SDD)](#spec-driven-development-sdd) under Tools).

  ## Testing Conventions

  - Use fixtures, not factories (FactoryBot is not in this project).
  - Test files mirror app structure: `app/models/user.rb` → `test/models/user_test.rb`.
  - System tests live in `test/system/` and use Capybara.
  - Don't mock the database — tests hit the real SQLite test DB.
  - Stub external HTTP with WebMock — don't hit the real network in tests.
  - Sign a user in for controller/integration tests with `SessionTestHelper` (`test/test_helpers/session_test_helper.rb`).
  - Coverage is tracked by SimpleCov (started in `test/test_helper.rb`; reports land in `coverage/`).

  ### TDD Workflow (required)

  Follow strict red-green TDD for every feature:

  1. **Write failing tests first.** Before writing any feature code, write the tests that describe the expected behavior. Run them and confirm they fail. Do not proceed until failure is verified.
  2. **Write the feature code.** Implement only enough code to make the tests pass.
  3. **Verify tests pass.** Run the tests again and confirm they are green. Do not end the session or mark a task complete until all tests pass.

  ## When in Doubt

  - Check `db/schema.rb` for the source of truth on database structure.
  - Check existing controllers and models for patterns before inventing new ones.
  - Ask before creating new abstractions or files not directly needed.

  ## Tools

  ### Spec-Driven Development (SDD)

  This project expects the **spec-driven-development** plugin (from Maquina's `rails-claude-code` marketplace). It provides a Rails-focused workflow that shapes feature ideas into specs, breaks them into ordered tasks, and tracks progress across sessions in an `sdd/` directory. Full docs: https://maquina.app/documentation/ai-tools/spec-driven-development/

  **Agents must confirm this plugin is available before planning or building a feature.** Verify the `/sdd-*` commands below appear in your available commands/skills. If they are missing, stop and prompt the user to install it — do not proceed with feature work without it. Install with:

  ```
  /plugin marketplace add maquina-app/rails-claude-code
  /plugin install spec-driven-development@maquina
  ```

  To enable it automatically for everyone on the project, add to `.claude/settings.json`:

  ```json
  { "enabledPlugins": ["spec-driven-development@maquina"] }
  ```

  Commands (run in order for a new feature):

  | Command | What it does |
  |---|---|
  | `/sdd-init` | Bootstrap `sdd/` — Rails standards, `index.yml`, and a progress tracker |
  | `/sdd-plan` | Create/update product mission, roadmap, and tech-stack docs |
  | `/sdd-discover-standards` | Extract coding standards from the existing codebase |
  | `/sdd-shape` | Shape a feature spec (questions → codebase search → `spec.md`) |
  | `/sdd-tasks` | Break the current spec into task groups with ready-to-run prompts |
  | `/sdd-status` | Show progress and suggest the next command |

  Run `/sdd-init` first — it creates the `sdd/` directory (with a `progress.yml` tracker). This repo is not yet initialized (no `sdd/` directory).

  ### Chrome MCP (Local Dev)

  URL: `http://localhost:3000`

  Use Chrome MCP tools to interact with the running dev app for UI testing and debugging.

  ## Coding style

  @STYLE.md

  CODE

end

get "https://github.com/basecamp/fizzy/raw/refs/heads/main/STYLE.md", "STYLE.md"

# ==========================
# SimpleCov
# ==========================
prepend_to_file "test/test_helper.rb" do
  "require \"simplecov\"\nSimpleCov.start \"rails\"\n\n"
end

# ==========================
# GIT
# ==========================
append_file '.gitignore', "# Ignore hidden system files\n.DS_Store\nThumbs.db\n"
append_file '.gitignore', "# Ignore SimpleCov files\ncoverage\n"

# =========================================================
# ENVIRONMENT
# =========================================================

# Generators
environment <<-CODE.strip_heredoc
  # Enable UUIDs for primary keys
  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end

  CODE


# =========================================================
# INITIALIZERS
# =========================================================

# ==================================
# config/initializers/enable_yjit.rb
# ==================================
initializer 'enable_yjit.rb', <<-CODE.strip_heredoc
  if defined? RubyVM::YJIT.enable
    Rails.application.config.after_initialize do
      RubyVM::YJIT.enable
    end
  end
  CODE

# =========================================================
# STATIC PAGES
# =========================================================
def install_static_pages
  rails_command("generate controller Pages welcome dashboard --skip-routes")

  inject_into_file "app/controllers/pages_controller.rb", after: "class PagesController < ApplicationController" do
    "\n  allow_unauthenticated_access only: %i[ welcome ]"
  end

  remove_file('app/views/pages/welcome.html.erb')

  file 'app/views/pages/welcome.html.erb' do
    <<-CODE.strip_heredoc
    <%= render "components/header" do %>
      <%= render "components/sidebar/trigger" %>
      <%= render "components/separator", orientation: :vertical %>
      <h1 class="text-sm font-medium">#{app_name.capitalize}</h1>
    <% end %>
    CODE
  end

  route 'root to: "pages#welcome"'
end


# =========================================================
# AFTER BUNDLE
# =========================================================
after_bundle do
  rails_command("generate rails_live_reload:install")
  rails_command("generate sqlite_crypto:install")
  rails_command("generate maquina_components:install")
  rails_command("generate authentication")
  install_static_pages
  run("bundle exec bin/setup --skip-server --reset")
  run("bundle exec bin/ci")
  git add: "."
  git commit: "-a -m 'Initial commit'"
  run("code .")
end
