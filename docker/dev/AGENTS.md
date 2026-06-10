# Docker Development

The Docker development environment uses configurations in `docker/dev/` and the `bin/compose` wrapper script.

## Setup

```bash
# Initial setup (first time only)
bin/compose setup                         # Installs backend and frontend dependencies

# Starting services
bin/compose start                         # Start backend and frontend in background
bin/compose run                           # Start frontend in background, backend in foreground (for debugging with pry)

# Running tests
bin/compose rspec spec/models/user_spec.rb   # Run specific tests in backend-test container

# Other operations
bin/compose reset                         # Remove all containers and volumes (requires setup again)
bin/compose <command>                     # Pass any docker-compose command directly
```

## Important Notes

- **CRITICAL**: `config/database.yml` must NOT exist when using Docker (rename or delete it)
- Most developers use a local `docker-compose.override.yml` for custom port mappings and configurations
- Copy `docker-compose.override.example.yml` to `docker-compose.override.yml` and customize as needed
- Default ports: Backend at http://localhost:3000 (or 4200 for frontend dev server)
- Services: `backend`, `frontend`, `worker`, `db`, `db-test`, `backend-test`, `cache`
- Persisted volumes: `pgdata`, `bundle`, `npm`, `tmp`, `opdata` (data survives container restarts)
- Docker build context: Uses Dockerfiles in `docker/dev/backend/` and `docker/dev/frontend/`

## Commands Reference

```bash
# Setup and lifecycle
bin/compose setup                        # Setup Docker environment (first time)
bin/compose start                        # Start all services in background
bin/compose run                          # Start frontend in background, backend in foreground
bin/compose reset                        # Remove all containers and volumes
bin/compose stop                         # Stop all services
bin/compose down                         # Stop and remove containers

# Testing
bin/compose rspec spec/models/user_spec.rb    # Run specific tests
bin/compose exec backend bundle exec rspec    # Run tests directly in backend container

# Development
bin/compose exec backend bundle exec rails console   # Rails console
bin/compose logs backend                 # View backend logs
bin/compose logs -f backend              # Follow backend logs
bin/compose ps                           # List running containers

# Database
bin/compose exec backend bundle exec rails db:migrate      # Run migrations
bin/compose exec backend bundle exec rails db:seed         # Seed data

# Direct docker-compose commands
bin/compose up -d                        # Start services
bin/compose restart backend              # Restart backend service
```
