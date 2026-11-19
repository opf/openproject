# App

## Directory Structure

- `app/components/` - ViewComponent-based UI components (Ruby + ERB)
- `app/contracts/` - Validation and authorization contracts
- `app/controllers/` - Rails controllers
- `app/models/` - ActiveRecord models
- `app/services/` - Service objects (business logic)
- `app/workers/` - Background job workers

## Code Style Guidelines

### Ruby
- Follow the [coding style](../docs/development/code-review-guidelines/README.md#coding-style)
- Use service objects for complex business logic (return `ServiceResult`)
- Use contracts for validation and authorization
- Keep controllers thin, models focused
- Where documentation is warranted, use [YARD](https://yardoc.org/) syntax — but see
  [code comments](../docs/development/style-guide/README.md#code-comments): self-descriptive methods get no docblock
- Write RSpec tests for all new features
- **Work package identifiers**: `WorkPackage.find("PROJ-42")` resolves semantic identifiers transparently. Use `find_by_display_id` only when input could legitimately be numeric OR semantic (controllers, URL-driven components, macro resolvers). Low-level code (queries, filters, services) should stick to `find_by(id:)` with primary keys. See `app/models/work_package/semantic_identifier/finder_methods.rb`.

### Templates
- Use ERB for server-rendered views
- Use ViewComponents for reusable UI (with Lookbook previews)
- Lint ERB as described in the [coding style](../docs/development/code-review-guidelines/README.md#coding-style) before committing

## Translations

- UI strings must use translation keys (never hard-coded); see the [translations concept](../docs/development/concepts/translations/README.md)
