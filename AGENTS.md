# OpenProject AI Coding Agent Instructions

> **Note for developers**: You can create `AGENTS.local.md` (or `CLAUDE.local.md`) in this directory to add your own custom instructions or preferences for AI coding agents. These files are git-ignored and will not be committed to the repository.

## Repository Overview

**OpenProject** is a web-based, open-source project management software written in Ruby on Rails with PostgreSQL for data persistence.

- **Size**: Large monorepo (~840MB, ~1M+ lines of code)
- **Backend**: Ruby 3.4.7, Rails ~8.0.3
- **Frontend**: Node.js 22.21.0, npm 10.1.0+, TypeScript
- **Database**: PostgreSQL (required)
- **Architecture**: Server-rendered HTML with Hotwire (Turbo + Stimulus). Legacy Angular components exist and are being migrated to custom elements. Uses GitHub's Primer Design System via ViewComponent.
- **Editions**: Community, Enterprise (SSO, LDAP, SCIM), and BIM (construction industry, code in `modules/bim/`)

## Critical Setup Requirements

**ALWAYS verify versions before building:**
- Ruby: `3.4.7` (see `.ruby-version`)
- Node: `^22.21.0` (see `package.json` engines)
- Bundler: Latest 2.x

### Local Development Setup

```bash
bundle install                    # Install Ruby gems
cd frontend && npm ci && cd ..   # Install Node packages
bundle exec rails db:migrate      # Setup database
bin/dev                          # Start all services (Rails, frontend, Good Job worker)
# Access at http://localhost:3000
```

### Docker Development Setup

See [`docker/dev/AGENTS.md`](docker/dev/AGENTS.md) for full Docker setup and commands.

## Project Structure

### Key Directories

- `app/` — Rails application code
- `config/` — Rails configuration, routes, locales
- `db/` — Database migrations and seeds
- `docker/dev/` — Docker development environment
- `frontend/` — TypeScript/Angular/Stimulus frontend
- `lib/` — Ruby libraries and extensions
- `lookbook/` — ViewComponent previews (<https://qa.openproject-edge.com/lookbook/>)
- `modules/` — OpenProject plugin modules
- `spec/` — RSpec test suite

### Configuration Files

- `.ruby-version` - Ruby version
- `.rubocop.yml` - Ruby linting rules
- `.erb_lint.yml` - ERB template linting
- `frontend/eslint.config.mjs` - JavaScript/TypeScript linting
- `Gemfile` - Ruby dependencies
- `package.json` / `frontend/package.json` - Node.js dependencies
- `lefthook.yml` - Git hooks configuration

### Linting (Run Before Committing)

```bash
# Ruby
bundle exec rubocop                              # Check all files
bin/dirty-rubocop --uncommitted                  # Check only uncommitted changes

# JavaScript/TypeScript
cd frontend && npx eslint src/ && cd ..

# ERB Templates
erb_lint {files}

# Install Git Hooks (recommended)
bundle exec lefthook install
```

## Commit Messages
- First line: < 72 characters, then blank line, then detailed description
- Reference work packages when applicable
- Merge strategy: "Merge pull request" (not squash), except single-commit PRs can use "Rebase and merge"

## Additional Documentation

- `docs/development/` — Development documentation
- `docs/development/running-tests/` — Testing guide
- `docs/development/code-review-guidelines/` — Code review standards
- `CONTRIBUTING.md` — Contribution workflow
- `.github/copilot-instructions.md` — Extended agent instructions with troubleshooting
