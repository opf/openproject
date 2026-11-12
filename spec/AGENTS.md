# Spec

## Directory Structure

- `spec/features/` - System/feature tests (Capybara)
- `spec/models/` - Model unit tests
- `spec/requests/` - API/integration tests
- `spec/services/` - Service tests

## Running Tests

Run the specific spec files or lines you changed (`bundle exec rspec path/to/file_spec.rb:42`) rather than the whole suite. For setup, system tests, and parallel runs (CI uses `turbo_tests`), see [Running tests locally](../docs/development/testing/running-tests-locally/README.md). In the Docker environment, use `bin/compose rspec path/to/file_spec.rb`.

## Debugging CI Failures

Use `script/github_pr_errors` to list failing specs from a CI run and `script/bulk_run_rspec` to rerun suspected flaky specs; see the [continuous testing workflow](../docs/development/testing/continuous-testing-workflow/README.md) and [flaky test guide](../docs/development/testing/handling-flaky-tests/README.md).
