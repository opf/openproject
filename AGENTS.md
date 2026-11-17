# OpenProject AI Coding Agent Instructions

> **Note for developers**: You can create `AGENTS.local.md` (or `CLAUDE.local.md`) in this directory to add your own custom instructions or preferences for AI coding agents. These files are git-ignored and will not be committed to the repository.

## Repository Overview

**OpenProject** is a web-based, open-source project management software written in Ruby on Rails with PostgreSQL for data persistence.

- **Size**: Large monorepo (~840MB, ~1M+ lines of code)
- **Backend**: Ruby on Rails
- **Frontend**: Node.js, npm, TypeScript
- **Database**: PostgreSQL (required)
- **Architecture**: New UI uses server-rendered HTML with Hotwire (Turbo + Stimulus) and GitHub's Primer Design System via ViewComponent. Remaining Angular components are being migrated to custom elements in the meantime.
- **Editions**: Community, Enterprise (SSO, LDAP, SCIM), and BIM (construction industry, code in `modules/bim/`)

## Setup and Dependency Versions

Before building or running checks, verify Ruby against [.ruby-version](.ruby-version), Node.js and npm against the engines in [package.json](package.json) and [frontend/package.json](frontend/package.json), and Bundler against `BUNDLED WITH` in [Gemfile.lock](Gemfile.lock). Rails and other gem requirements are defined in [Gemfile](Gemfile).

- For native setup, read the [development environment guide](docs/development/development-environment/README.md) and follow the instructions for your operating system.
- For Docker setup and commands, read the [Docker development setup](docs/development/development-environment/docker/README.md).
- For setup or asset failures, consult the [development FAQ](docs/development/faq/README.md).

## Project Structure

### Key Directories

- `app/` — Rails application code
- `config/` — Rails configuration, routes, locales
- `db/` — Database migrations and seeds
- `docker/dev/` — Docker development environment
- `frontend/` — TypeScript frontend (Stimulus/Turbo; legacy Angular)
- `lib/` — Ruby libraries and extensions
- `lookbook/` — ViewComponent previews (<https://qa.openproject-edge.com/lookbook/>)
- `modules/` — OpenProject plugin modules
- `spec/` — RSpec test suite

## Checks Before Committing

Run the linters and tests relevant to the changed files:

- Ruby and ERB: follow the [code review guidelines](docs/development/code-review-guidelines/README.md#coding-style); use [lefthook.yml](lefthook.yml) for the configured checks.
- JavaScript and TypeScript: follow the [frontend formatting guide](docs/development/style-guide/frontend/README.md#code-format) and run the [frontend typecheck](docs/development/testing/running-tests-locally/README.md#frontend-tests).
- Tests: use [Running tests locally](docs/development/testing/running-tests-locally/README.md); for CI-only or intermittent failures, read the [continuous testing workflow](docs/development/testing/continuous-testing-workflow/README.md) and [flaky test guide](docs/development/testing/handling-flaky-tests/README.md).

## Copyright Notices

Use the applicable `copyright:update_*` Rake task or ESLint autofix to generate or repair notices where supported. Copy an existing notice manually only if neither tool can add a missing notice for the file type. See [copyright notices](docs/development/style-guide/README.md#copyright-notices) for commands and format guidance.

## Code Comments

Full rules: [code comments guide](docs/development/style-guide/README.md#code-comments). In short:

- Default to zero comments. Never restate what the code does or justify the chosen approach; that belongs in the commit message.
- Only comment constraints the code cannot express (upstream workaround, non-obvious edge case, ordering, invariant), linking the work package or issue.
- No YARD/JSDoc headers on self-descriptive methods. Use en-us spelling.

## Task-Specific Documentation

- Commits and pull requests: follow the [code review guidelines](docs/development/code-review-guidelines/README.md), including commit messages and merge strategy, and the [development workflow](docs/development/git-workflow/README.md) for branch names and which branch to target.
- Primer components and icons: read the [design system guide](docs/development/design-system/README.md), which links the maintained source repositories and Lookbook.
- CKEditor: read the [WYSIWYG editor concept](docs/development/concepts/wysiwyg-editor/README.md) for the custom build repository and integration requirements.
- Service objects and results: follow [application architecture](docs/development/application-architecture/README.md#service-objects).
- Database migrations: read the [migration guide](docs/development/migrations/README.md), including migration squashing between major versions.
