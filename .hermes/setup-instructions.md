# CDE Plugin - Manual Setup Instructions

## Current Status

All code fixes are complete. The plugin is ready for installation once Ruby is available.

## Fixes Applied

### 1. Migrations
- Copied 5 migration files to `modules/cde/db/migrate/`
- Changed `t.jsonb` to `t.text` for PostgreSQL compatibility

### 2. Configuration
- Created `config/cde_conventions.yml` with all required settings

### 3. Dependencies
- Added `gem 'aasm', '~> 5.5'` to `Gemfile.modules`

### 4. Models
- Added JSON hash accessors to `AuditEvent`

## Installing Ruby

The system cannot install Ruby automatically due to SSL certificate issues.

**Option 1: Download RubyInstaller**
1. Go to https://rubyinstaller.org/downloads/
2. Download Ruby 3.3.12-1 (with DevKit)
3. Run installer and add Ruby to PATH
4. Open new terminal and verify: `ruby --version`

**Option 2: Use existing OpenProject Docker**
```bash
cd D:/nexuscde
docker-compose up -d
docker exec -it nexuscde-backend bash
```

## After Ruby Installation

```bash
cd D:/nexuscde

# Install gems
bundle install

# Run migrations
bundle exec rake db:migrate

# Run tests
bundle exec rspec modules/cde/spec/integration/

# Verify plugin loads
bundle exec rails runner "puts Cde::Engine.name"
```

## Slice Status

| Slice | Status |
|-------|--------|
| 1-6, 9 | ✅ Infrastructure complete |
| 7, 8 | ⏳ Pending |
| 10-14 | ⏳ Pending |

## Files Modified

- `D:/nexuscde/Gemfile.modules` - Added aasm gem
- `D:/nexuscde/modules/cde/config/cde_conventions.yml` - Created config
- `D:/nexuscde/modules/cde/db/migrate/*.rb` - Copied migrations
- `D:/nexuscde/modules/cde/app/models/cde/audit_event.rb` - Added JSON helpers
