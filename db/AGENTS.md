# Database

## Code Style

### Database Migrations
- Follow Rails migration conventions
- Migrations are "squashed" between major releases (see `docs/development/migrations/`)

## Commands

### Local

```bash
bundle exec rails g migration MigrationName  # Generate a migration
bundle exec rails db:migrate                 # Run migrations
bundle exec rails db:rollback                # Rollback last migration
bundle exec rails db:seed                    # Seed sample data
```

### Docker

```bash
bin/compose exec backend bundle exec rails db:migrate      # Run migrations
bin/compose exec backend bundle exec rails db:seed         # Seed data
```

## Important Note

**CRITICAL**: `config/database.yml` must NOT exist when using Docker (rename or delete it)
