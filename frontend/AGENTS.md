# Frontend

## Directory Structure

- `./src/app/` — legacy Angular modules and components
- `./src/common/` — framework-agnostic modules (the `core-common` alias)
- `./src/stimulus/` — Stimulus controllers
- `./src/turbo/` — Turbo integration

Where a given module belongs is explained in [doc/README.md](./doc/README.md#directory-structure).

## Version Requirements

- Node: `^24.15.0` (see `engines` in the repository root `../package.json`)

## Commands

```bash
npm ci               # install packages
npx eslint src/      # lint
npm run typecheck    # typecheck application and spec sources
npm test             # run the specs
```

## Code Style

New development uses Hotwire (Turbo + Stimulus) with server-rendered HTML and [Primer](https://primer.style/product/) via ViewComponent; the Angular tree is legacy. Prefer TypeScript over JavaScript.

Patterns and formatting conventions: [frontend style guide](../docs/development/style-guide/frontend/README.md).
Components and design system: [design system](../docs/development/design-system/README.md).

## Further documentation

- [doc/TESTING.md](./doc/TESTING.md) — writing frontend specs, the Stimulus helpers, coverage
- [doc/PLUGINS.md](./doc/PLUGINS.md) — linking plugin frontends during development
- [doc/README.md](./doc/README.md) — dev server, builds, dependencies
- [Sortable lists selection contract](src/stimulus/controllers/dynamic/sortable-lists/README.md) — consumer wiring, item identity, selection gestures, and presentation
