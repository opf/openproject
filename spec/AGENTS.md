# Spec

## Directory Structure

- `spec/features/` - System/feature tests (Capybara)
- `spec/models/` - Model unit tests
- `spec/requests/` - API/integration tests
- `spec/services/` - Service tests

## Running Tests

```bash
# Backend (RSpec) - prefer specific tests over running all
bundle exec rspec spec/models/user_spec.rb              # Single file
bundle exec rspec spec/models/user_spec.rb:42           # Single line
bundle exec rspec spec/features                         # Directory
bundle exec rake parallel:spec                          # Parallel execution
```

### Docker

```bash
bin/compose rspec spec/models/user_spec.rb   # Run specific tests in backend-test container
bin/compose exec backend bundle exec rspec    # Run tests directly in backend container
```

## Debugging CI Failures

```bash
./script/github_pr_errors | xargs bundle exec rspec    # Run failed tests from CI
./script/bulk_run_rspec spec/path/to/flaky_spec.rb     # Run tests multiple times
```
