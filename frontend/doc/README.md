# Developing OpenProject Frontend

The OpenProject frontend is split into two parts:

- **The legacy webpack bundle** is located at `frontend/legacy` and contains AngularJS
from the previous frontend that cannot be converted to Angular. (Mainly because they're used in Rails partials with content within)
- **The Angular frontend** is located at `frontend/src` and uses the Angular CLI to compile and serve locally.


## Angular frontend

When developing, `npm run serve` will open a proxy server (webpack-dev-server) that will serve assets from memory.
That server is running on `http://localhost:4200` by default and will forward all requests it cannot handle to the Rails server
which it expects to run at `http://localhost:3000`.

You can always access the Rails server with `http://localhost:3000`
and it will forward the requests to the CLI Proxy unless an empty ENV variable `OPENPROJECT_CLI_PROXY='''` is passed to it.

Then, Rails will try to locate the asset on disk (e.g., as output from the `rake assets:precompile` task).
This is also what happens in production mode.

To learn more about how this behavior works in detail, see the asset helper at `app/helpers/frontend_asset_helper.rb`.

The proxy definition can be found at `frontend/cli_to_rails_proxy.js`.

### Ahead-of-Time compilation (AOT)

In development, by default AOT is disabled. You can force it in by running `npm run serve --aot`.
For production builds with `ng build --prod`, `--aot` is enabled by default as per the `frontend/angular.json` configuration.

### Production builds

Production builds can be triggered either through the `rake assets:precompile` rake task (which will compile legacy and angular frontend)
or by running `npm build --prod` manually.

## Tests

Tests are run with karma-jasmine through the Angular CLI `ng test`. To watch the test output, use `ng test --watch`.
Only files ending with `.spec.ts` will be matched and compiled.

For more information, see [TESTING](./TESTING.md).

## Plugins

OpenProject Community Edition has some plugins that contain a frontend,
e.g., [Costs](https://github.com/finnlabs/openproject-costs/)
or [My Project Page](https://github.com/finnlabs/openproject-my_project_page/).

For developing these plugins, they need to be linked so either the Legacy or Angular frontend can see and process them.
For more information on that part, see [PLUGINS](./PLUGINS.md)



## Living Style Guide

The style guide is available as part of the Rails development server at: <http://localhost:3000/styleguide>.

For more information on styling the application, see [STYLING](./STYLING.md).

## Changing or updating Dependencies

We use `npm shrinkwrap` to lock down runtime (but not development)
dependencies. When adding or removing dependencies, please adhere to the
following workflow:

    npm install
    npm shrinkwrap

Please commit `npm-shrinkwrap.json` along with any changes to `package.json`.

## Topics

The individual topics for the documentation for the frontend are

1. `TESTING.md` - documentation of our approach to integration and unit testing
2. `STYLING.md` - notes on styling and the Sass-Pipeline
3. `API.md` - notes on dealing with the several APIs provided by OpenProject
4. `LEGACY.md` - contains additional information on how to use the legacy bundle
5. `PLUGINS.md` - contains additional information on how to link plugins with a frontend during development.
