# OpenProject Test Management

Test cases in folders, test runs with iterations, GitHub CI result ingest and "Run in CI",
project/admin settings, and admin AI provider configuration.

## Documentation

- [Overview](docs/README.md)
- [Test cases](docs/cases.md)
- [Test runs](docs/runs.md)
- [CI and automation](docs/ci/README.md)
- [API](docs/api.md)
- [Settings](docs/settings.md)

APIv3 endpoints are under `docs/api/apiv3` (tag *Test Management*).

## Enable

1. Ensure the gem is listed in `Gemfile.modules`.
2. `bundle install && rake db:migrate`
3. Project → Settings → Modules → enable **Test management**.
