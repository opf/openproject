# OpenProject Coding Agent Instructions

See [AGENTS.md](../AGENTS.md) for all agent instructions.

## Additional Context for GitHub Copilot

### Common Issues and Workarounds

#### Database Configuration
- **Issue**: Docker fails with "database.yml exists"
- **Fix**: Delete or rename `config/database.yml` when using Docker

#### Memory Issues in Docker
- **Issue**: Frontend container exits with status 137
- **Fix**: Increase Docker memory limit to at least 4GB

#### Test Failures on CI but Passing Locally
- Run with `CI=true` environment variable (eager loads app)
- Check for `OPENPROJECT_*` environment variables
- Match the random seed: `bundle exec rspec --seed 18352`
- Use `--bisect` to find order-dependent failures
- View browser tests with `OPENPROJECT_TESTING_NO_HEADLESS=1`

#### Frontend Build Issues
- **Issue**: "jQuery not defined", frontend asset errors, or blank page
- **Fix**: Run `bin/setup_dev` to rebuild frontend completely

#### Parallel Test Failures
- Tests run in parallel on CI with different random seeds per group
- Check `tmp/parallel_runtime.log` for execution times
- **Flaky specs**: Some tests may fail randomly; see [`docs/development/testing/handling-flaky-tests/README.md`](../docs/development/testing/handling-flaky-tests/README.md) for the full playbook, including the Turbo-aware waiting helpers and a pattern→fix table for feature specs
  - Use `script/bulk_run_rspec` to run tests multiple times to identify flaky behavior

### Extended Details

#### Service Objects and Result Modeling
- Return results using the `ServiceResult` class (well-documented in codebase)
- Some services use monads via [dry-monads](https://github.com/dry-rb/dry-monads) for result modeling

#### Testing with Capybara
- Feature specs use Capybara (with Cuprite and Selenium WebDriver)
- Feature specs can use A11y selectors ([capybara_accessible_selectors](https://github.com/citizensadvice/capybara_accessible_selectors)), test IDs, or page objects (in `spec/support/pages/`)

#### Database Migrations
- OpenProject implements migration "squashing" between major releases
- See `docs/development/migrations/` for details on the squashing process
- Migrations are consolidated to manage database changes across major versions
- OpenProject does not currently aim for zero downtime migrations

#### Design System Components
- [primer_view_components](https://github.com/opf/primer_view_components) - OpenProject's fork of Primer Rails/ViewComponent
- [openproject-octicons](https://github.com/opf/openproject-octicons) - OpenProject's fork of Primer Octicons
- [commonmark-ckeditor-build](https://github.com/opf/commonmark-ckeditor-build) - Custom CKEditor build with CommonMark Markdown support

#### Enterprise and BIM Editions
- **Enterprise Edition**: Includes additional features like Single sign-on (OIDC & SAML), LDAP, Nextcloud integration, SCIM API, and more (requires token for development)
- **BIM Edition**: Tailored for construction industry needs. Code in `modules/bim/`, docs in `docs/bim-guide/`. Existing instances can be switched to BIM edition.

#### GitHub Actions CI/CD
- **test-core.yml** - Main test suite (units + features, ~40 min, runs on all PRs)
- **rubocop-core.yml** - Ruby linting (runs on all PRs with Ruby changes)
- **eslint-core.yml** - JS/TS linting (runs on all PRs with JS/TS changes)
- **test-frontend-unit.yml** - Frontend unit tests
- **brakeman-scan-core.yml** - Security scanning
- **codeql-scan-core.yml** - Code quality/security analysis
- **Skip CI**: Add `[ci skip]` to commit message to skip CI (use sparingly)

#### Performance Considerations
- Main test suite: 40 minutes timeout
- Full Docker build: ~10-15 minutes (first time)
- Bundle install: ~2-5 minutes
- npm install: ~3-7 minutes

### Additional Commands

```bash
# Database
bundle exec rake db:migrate:status       # Check migration status

# Frontend
bundle exec rails openproject:plugins:register_frontend assets:export_locales

# Docker
bin/compose run                          # Run with backend in foreground
docker compose run --rm backend-test "bundle exec rspec spec/features/work_package_show_spec.rb"
```

For detailed documentation, consult:
- `docs/development/` - Development documentation
- `docs/development/running-tests/` - Testing guide
- `docs/development/code-review-guidelines/` - Code review standards
- `CONTRIBUTING.md` - Contribution workflow
