# Docker Development

Setup, services, volumes, and commands are documented in the [Docker development setup](../../docs/development/development-environment/docker/README.md). Agent-specific hints:

- `config/database.yml` must NOT exist when using Docker; `bin/compose` refuses to run while it does.
- Run commands inside the containers via `bin/compose exec backend …` (e.g. `bin/compose exec backend bundle exec rails db:migrate`), not on the host.
- Run specs in the `backend-test` container with `bin/compose rspec path/to/file_spec.rb`.
- Local port mappings and other overrides live in an untracked `docker-compose.override.yml`; don't assume default ports.
