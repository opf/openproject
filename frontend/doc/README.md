# Developing OpenProject Frontend

The OpenProject frontend is located at `frontend/src` and uses the Angular CLI (which itself uses Vite in dev and esbuild in production) to compile and serve locally.

## Directory structure

- `src/app/` — the legacy Angular application. New work does not go here.
- `src/common/` — framework-agnostic modules, reachable through the `core-common` alias and importable from both Angular and Stimulus. Code belongs here when it depends on neither framework and both sides need it; a helper only Stimulus controllers use belongs in `src/stimulus/helpers/` instead.
- `src/stimulus/` — Stimulus controllers, the current approach for new behaviour.
- `src/turbo/` — Turbo integration: stream actions, custom elements and helpers.

## Angular frontend

When developing, `npm run serve` starts the Angular CLI dev server (Vite) on `http://localhost:4200`, serving frontend assets from memory. It is not a general-purpose proxy: it forwards only `/api` and `/assets/frontend/media` to Rails, as configured in `frontend/src/proxy.conf.mjs`.

Application pages are reached through Rails at `http://localhost:3000`, which forwards frontend asset requests to the dev server unless `OPENPROJECT_CLI_PROXY=''` is passed to it.

Then, Rails will try to locate the asset on disk (e.g., as output from the `rake assets:precompile` task).
This is also what happens in production mode.

To learn more about how this behavior works in detail, see the asset helper at `app/helpers/frontend_asset_helper.rb`.

### Production builds

Production builds are triggered either through the `rake assets:precompile` rake task, which compiles
the frontend along with the rest of the assets, or by running `npm run build` manually. That script
builds with `--configuration production`, which enables ahead-of-time compilation.

## Tests

Tests run with `npm run test`, which uses the Angular CLI's `ng test` to build the specs and
[Vitest](https://vitest.dev/) to execute them in a real browser. Use `npm run test:watch` to watch.
Only files ending with `.spec.ts` are matched.

For more information, see [TESTING](./TESTING.md).

## Plugins

OpenProject Community edition has some plugins that contain a frontend,
e.g., Costs, which lives in this repository at `modules/costs`.

For developing these plugins, they need to be linked so either the Legacy or Angular frontend can see and process them.
For more information on that part, see [PLUGINS](./PLUGINS.md)



## Components and styling

Component documentation and previews live in Lookbook, served by the Rails development server at <http://localhost:3000/lookbook> when `lookbook_enabled` is set. See [Design system](https://www.openproject.org/docs/development/design-system/) for Primer and the component library.

Styles live under `frontend/src`: shared rules in `global_styles`, component styles beside their components, with `styles.scss` and `spot.scss` as the build entry points declared in `frontend/angular.json`.

## Stimulus API documentation

Generate the TypeDoc reference for Stimulus controllers, helpers, mixins, and support modules with:

```shell
npm run generate-docs
```

The command registers plugin frontends before writing the ignored output to `generated-docs/`.
Open `generated-docs/index.html` to browse it locally.

## Changing or updating Dependencies

We use a `package-lock` to lock down dependencies, development ones included. When adding or removing dependencies, please use `npm install` to also update the lockfile.
Please commit `package-lock.json` along with any changes to `package.json`.

If you want to install the packages from the lockfile without updating it, please use the following command:

```
npm ci
```

## Topics

Frontend-specific documentation:

1. [TESTING.md](./TESTING.md) — writing frontend specs, the Stimulus helpers, coverage
2. [PLUGINS.md](./PLUGINS.md) — linking plugin frontends during development

Frontend topics documented alongside the rest of the application:

- [Frontend style guide](https://www.openproject.org/docs/development/style-guide/frontend/) — code format and development patterns
- [Design system](https://www.openproject.org/docs/development/design-system/) — Primer and the component Lookbook
- [Running tests locally](https://www.openproject.org/docs/development/testing/running-tests-locally/#frontend-tests) — how to invoke the suite
- [Testing architecture](https://www.openproject.org/docs/development/testing/) — where frontend specs sit in the wider strategy
