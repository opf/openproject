# Frontend

## Directory Structure

- `./src/app/` — legacy Angular modules and components
- `./src/common/` — framework-agnostic modules (the `core-common` alias)
- `./src/stimulus/` — Stimulus controllers
- `./src/turbo/` — Turbo integration

Where a given module belongs is explained in [doc/README.md](./doc/README.md#directory-structure).

## Commands

Check Node.js and npm against `engines` in [package.json](./package.json) and the repository root [package.json](../package.json). Lint, typecheck, and test commands: [frontend tests](../docs/development/testing/running-tests-locally/README.md#frontend-tests) and [code format](../docs/development/style-guide/frontend/README.md#code-format).

## Code Style

New UI uses Hotwire (Turbo + Stimulus) with server-rendered HTML and [Primer](https://primer.style/product/) via ViewComponent. Remaining Angular components are being migrated to custom elements in the meantime. Prefer TypeScript over JavaScript.

Patterns and formatting conventions: [frontend style guide](../docs/development/style-guide/frontend/README.md).
Components and design system: [design system](../docs/development/design-system/README.md).

## Further documentation

- [doc/TESTING.md](./doc/TESTING.md) — writing frontend specs, the Stimulus helpers, coverage
- [doc/PLUGINS.md](./doc/PLUGINS.md) — linking plugin frontends during development
- [doc/README.md](./doc/README.md) — dev server, builds, dependencies
- [Sortable lists selection contract](src/stimulus/controllers/dynamic/sortable-lists/README.md) — consumer wiring, item identity, selection gestures, and presentation
