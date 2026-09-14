# OpenProject AI Coding Agent Instructions

> **Note for developers**: You can create `AGENTS.local.md` (or `CLAUDE.local.md`) in this directory to add your own custom instructions or preferences for AI coding agents. These files are git-ignored and will not be committed to the repository.

## Repository Overview

**OpenProject** is a web-based, open-source project management software written in Ruby on Rails with PostgreSQL for data persistence.

- **Size**: Large monorepo (~840MB, ~1M+ lines of code)
- **Backend**: Ruby 3.4.7, Rails ~8.0.3
- **Frontend**: Node.js 24.x (>= 24.15.0), npm 11.x, TypeScript
- **Database**: PostgreSQL (required)
- **Architecture**: Server-rendered HTML with Hotwire (Turbo + Stimulus). Legacy Angular components exist and are being migrated to custom elements. Uses GitHub's Primer Design System via ViewComponent.
- **Editions**: Community, Enterprise (SSO, LDAP, SCIM), and BIM (construction industry, code in `modules/bim/`)

## Critical Setup Requirements

**ALWAYS verify versions before building:**
- Ruby: `3.4.7` (see `.ruby-version`)
- Node: `^24.15.0` (see `package.json` engines)
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

### JavaScript and TypeScript Copyright Headers

All first-party JavaScript and TypeScript files must use the canonical compact
line-comment copyright header generated from `COPYRIGHT_short`:

```typescript
//-- copyright
// OpenProject is an open source project management software.
// ...
//++

```

Use `//-- copyright` and `//++` exactly as shown. Prefix non-empty body lines
with `// `, prefix empty body lines with `//`, and leave one blank line between
the header and the source code. Do not compose or reformat the header manually.

Run `rake copyright:update_typescript` to add or repair headers in `.ts` and
`.tsx` files. Run `rake copyright:update_js` for `.js`, `.mjs`, and `.cjs`
files. Both commands accept an optional path argument.

## Code Comments

Readers are domain experts who know Ruby, Rails, TypeScript, and the patterns used here.
Write self-explanatory code instead of comments.

- Default to zero comments. Sparse is the goal, not thorough coverage.
- Never restate what the code plainly does (`# increments the counter` above `counter += 1`).
  These get flagged in review.
- Never justify the chosen approach. If a comment names a rejected alternative
  ("EXISTS rather than a join because…"), delete it — that reasoning belongs in the commit
  message or PR description, not the source.
- Do comment to explain a constraint the code cannot express itself: a workaround for an
  upstream bug, a non-obvious edge case, an ordering requirement, an invariant the caller
  must uphold. Link the work package or upstream issue when there is one.
- Don't add YARD/JSDoc headers to self-descriptive methods. Only where generated
  documentation is actually consumed.
- More than a handful of comments in a file is a smell: extract better-named methods,
  variables, and objects so the code explains itself.
- When in doubt, delete the comment rather than shortening it.

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
