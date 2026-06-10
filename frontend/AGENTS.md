# Frontend

## Directory Structure

- `./src/` - Frontend code
  - `./src/app/` - Legacy Angular modules/components
  - `./src/stimulus/` - Stimulus controllers
  - `./src/turbo/` - Turbo integration

## Configuration Files

- `eslint.config.mjs` - JavaScript/TypeScript linting
- `../package.json` / `./frontend/package.json` - Node.js dependencies

## Version Requirements

- Node: `^22.21.0` (see `package.json` engines)

## Setup

```bash
npm ci && cd ..   # Install Node packages
```

## Code Style

### JavaScript/TypeScript
- **New development**: Use Hotwire (Turbo + Stimulus) with server-rendered HTML
- **Legacy code**: Follow ESLint rules
- Prefer TypeScript over JavaScript
- Use [Primer Design System](https://primer.style/product/) via ViewComponent

## Linting

```bash
# JavaScript/TypeScript
npx eslint src/ && cd ..
```

## Testing

```bash
# Frontend (Jasmine/Karma)
npm test && cd ..
```
