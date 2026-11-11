---
sidebar_navigation:
  title: Running tests locally
description: How to run the OpenProject frontend, unit and system tests on your machine
keywords: testing, rspec, vitest, parallel tests, turbo_tests
---

# Running tests locally

As there are multiple ways employed to test OpenProject, you may want to run a specific test or test group.

## Prerequisites

In order to be able to run tests locally, you need to have set up a local development stack.

### Verifying your dependencies

To ensure your local installation is up to date and prepared for development or running tests, there is a helper script `./bin/setup_dev` that installs backend and frontend dependencies. When switching branches or working on a new topic, it is recommended to run this script again.

### Setting up a test database

As part of the development environment guides, you will have created a development and test database and specified it under `config/database.yml`:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  host: localhost
  username: openproject
  password: openproject-dev-password

development:
  <<: *default
  database: openproject_dev

test:
  <<: *default
  database: openproject_test
```

The configuration above determines that a database called `openproject_test` is used for the backend unit and system tests. The entire contents of this database is being removed during every test suite run.

Before you can start testing, you will often need to run the database migrations first on the development and the test database. You can use the following rails command for this:

```shell
RAILS_ENV=development rails db:migrate db:test:prepare
```

This migrates the _development_ database, outputting its schema to `db/structure.sql` and will copy this schema to the test database. This ensures your test database matches your current expected schema.

## Frontend tests

To run JavaScript frontend tests, first ensure you have all necessary dependencies installed via npm (i.e. `npm install`).

You can run all frontend tests with the standard npm command:

```shell
npm test
```

The specs run in browsers driven by [Playwright](https://playwright.dev/). If the browsers are not installed yet, install them from the `frontend/` folder:

```shell
npx playwright install chromium firefox webkit
```

`npm test` runs the suite in headless Chromium. CI additionally runs Firefox and WebKit; to reproduce that locally, pass the browsers explicitly:

```shell
npm test -- --browsers chromium --browsers firefox --browsers webkit
```

Alternatively, when in the `frontend/` folder, you can also use the watch mode of Angular to automatically run tests after you changed a file in the frontend.

```shell
./node_modules/.bin/ng test --watch
```

CI additionally typechecks the application and spec sources with `tsc`, which reports errors that the build and the test run can miss. To reproduce that locally, run the following in the `frontend/` folder:

```shell
npm run typecheck
```

For guidance on writing frontend specs — the Stimulus test helpers, Testing Library queries and coverage — see [frontend/doc/TESTING.md](https://github.com/opf/openproject/blob/dev/frontend/doc/TESTING.md).

## Unit tests

After following the prerequisites, use the following command to run individual specs:

```shell
RAILS_ENV=test bundle exec rspec spec/models/work_package_spec.rb
```

Run multiple specs by separating them with spaces:

```shell
RAILS_ENV=test bundle exec rspec spec/models/work_package_spec.rb spec/models/project_spec.rb
```

## System tests

System tests are also called _rspec feature specs_ and use [Capybara](https://rubydoc.info/github/teamcapybara/capybara/master) to run. They are automatically executed with an actual browser when `js: true` is set. The default browser driver is [Cuprite](https://github.com/rubycdp/cuprite). Some specs use [Selenium](https://www.selenium.dev/documentation/webdriver/). See [Browser drivers](../browser-drivers/) for when to use which driver.

To run feature specs, it is important that the frontend assets are being served. This is done by running `npm run serve`
in a separate terminal tab. This will start the Angular CLI and serve the frontend assets on `http://localhost:4200`.
Otherwise, the tests will fail because JavaScript and CSS assets are not available.

System tests are located in `spec/features`. Use the following command to run individual test:

```shell
RAILS_ENV=test bundle exec rspec spec/features/auth/login_spec.rb
```

When feature specs are run and a failure occurs, the browser logs are printed to the console. This can be helpful for
debugging, but it can also be overwhelming when there are many logs. To disable this behavior, set the environment
variable `SKIP_CAPYBARA_BROWSER_LOGS` to `true` in your `.env` file or export it in your terminal session:

```shell
export SKIP_CAPYBARA_BROWSER_LOGS=true
```

### Dependencies

For the javascript dependent integration tests, you have to install Chrome and Firefox, to run them locally.

Capybara uses Cuprite to drive Chrome and perform the actions we describe in each spec. Specs that need a Selenium driver use Chrome and Chromedriver, and some of them need Firefox. See [Browser drivers](../browser-drivers/) for the details.

### Running system tests

Almost all system tests depend on the browser for testing, you will need to have the Angular CLI running to serve frontend assets.

So with `npm run serve` running and completed in one tab, run the test using `rspec` as for the unit tests:

```shell
RAILS_ENV=test bundle exec rspec ./modules/documents/spec/features/attachment_upload_spec.rb[1:1:1:1]
```

The tests will generally run a lot slower due to the whole application being run end-to-end, but these system tests will provide the most elaborate tests possible.

You can also run _all_ feature specs locally, see [Parallel testing](#parallel-testing). This is not recommended due to the required execution time. Instead, prefer to select individual tests that you would like to test and let GitHub Actions CI test the entire suite.

#### WSL2

In case you are on Windows using WSL2 rather than Linux directly, install Chrome or Chromium inside your WSL2 distribution, as Cuprite needs to find a local browser binary. Otherwise you will see an error like "Failed to find Chrome binary".

Specs that use Selenium can alternatively run against a Selenium Grid on the Windows host. Point `SELENIUM_GRID_URL` to the grid and set `CAPYBARA_APP_HOSTNAME` to an address of your WSL2 instance that the browser on Windows can reach. The test server only listens on `127.0.0.1` by default, so also bind it to all interfaces with `CAPYBARA_BIND_ADDRESS`:

```shell
export SELENIUM_GRID_URL=http://<Windows host IP>:4444/wd/hub
export CAPYBARA_APP_HOSTNAME=`hostname -I | cut -d ' ' -f 1`
export CAPYBARA_BIND_ADDRESS=0.0.0.0
```

### Headless testing

Browser tests run headless by default, with Cuprite and with Selenium. This means that you do not see the browser that is being tested. Sometimes you will want to see what the test is doing to debug. To override this behavior and watch the Chrome or Firefox instance set the ENV variable `OPENPROJECT_TESTING_NO_HEADLESS=1`.

#### Troubleshooting

```text
Failure/Error: raise ActionController::RoutingError, "No route matches [#{env['REQUEST_METHOD']}] #{env['PATH_INFO'].inspect}"

     ActionController::RoutingError:
       No route matches [GET] "/javascripts/locales/en.js"
```

If you get an error like this when running feature specs it means your assets have not been built.
You can fix this either by accessing a page locally (if the rails server is running) once or by ensuring the `bin/setup_dev` script has been run.

## Entire local RSpec suite

You can run the specs with the following commands:

- `bundle exec rake spec` Run all core specs and feature tests. Again ensure that the Angular CLI is running for these to work. This will take a long time locally, and it is not recommend to run the entire suite locally. Instead, wait for the test suite run to be performed on GitHub Actions CI as part of your pull request.

- `SPEC_OPTS="--seed 12935" bundle exec rake spec` Run the core specs with the seed 12935. Use this to control in what order the tests are run to identify order-dependent failures. You will find the seed that GitHub Actions CI used in their log output.

## Ruby coverage

Set `COVERAGE=1` to collect Ruby line and branch coverage with SimpleCov. This starts
before Rails loads and includes `app`, `lib`, `lib_static`, module `app`/`lib` code,
and evaluated ERB templates from those directories.
It does not measure browser JavaScript coverage. Coverage is disabled by default.

Use a fresh output directory for each run or comparison:

```shell
mkdir -p coverage
export COVERAGE_DIR=$(mktemp -d coverage/rspec.XXXXXX)
COVERAGE=1 bundle exec rspec spec/models/project_spec.rb
```

After the tests succeed, generate HTML and JSON reports:

```shell
bundle exec ruby script/coverage_report "$COVERAGE_DIR" 1
```

Open `$COVERAGE_DIR/report/index.html`. The final argument is the expected number of
RSpec processes. Each process writes a separate resultset, and report generation fails
if the expected number is missing. Reusing a directory can mix results from different
runs, so always start with a fresh directory.

For units and features in one parallel CI job, use the same `COVERAGE_DIR` for both
phases and collate once after they both succeed. For example, 32 unit workers and
16 feature workers produce 48 reports; a separate final retry process adds another.
`COVERAGE_SUITE` optionally labels the phase in the report. Pass these environment
variables into containers explicitly and collate in the same environment and checkout
used by the tests, before editing source files. If tests used mounted source overrides,
report generation must see those same source files.

Focused runs include unloaded Ruby files at zero coverage, so their aggregate percentage
is not a full-suite coverage result. Unloaded ERB is not assigned guessed executable
lines. Compare affected lines and branches together with retained behavior assertions;
code coverage does not prove equivalent UI, permission, or browser interaction checks.
Run performance comparisons without coverage instrumentation.

## Parallel testing

Running tests in parallel makes use of all available cores of the machine. CI runs the RSpec suite with [turbo_tests](https://github.com/opf/turbo_tests), which builds on the [parallel_tests](https://github.com/grosser/parallel_tests) gem. See `run_units` and `run_features` in `docker/ci/entrypoint.sh` for the exact commands.

### Prepare

Each process uses its own test database, numbered through the `TEST_ENV_NUMBER` environment variable. Adjust `database.yml` to use different databases:

```yaml
test: &test
  database: openproject_test<%= ENV['TEST_ENV_NUMBER'] %>
  # ...
```

By default, the number of processes is the CPU count. This might be a bit much to handle for your system when 8 or more parallel browser instances are being run. To manually set the number of databases to create and tests to run in parallel, use this command:

```shell
export PARALLEL_TEST_PROCESSORS=4
```

`turbo_tests` numbers its processes starting at 1, while the `parallel:` tasks leave the first database without a number by default. Make them number the databases the same way, as CI does:

```shell
export PARALLEL_TEST_FIRST_IS_1=true
```

First migrate and dump your current development schema with `RAILS_ENV=development ./bin/rails db:migrate db:schema:dump` (will create a `db/structure.sql`).

Then create and prepare all test databases with `RAILS_ENV=test ./bin/rails parallel:create parallel:prepare`.

### RSpec specs

Run the unit specs and the feature specs the way CI does, with the same number of processes as test databases (the globs need `shopt -s extglob globstar` in bash):

```shell
# Unit specs
RAILS_ENV=test bundle exec turbo_tests -n 4 {,modules/*/}spec/{!(features)/**/,}*_spec.rb

# Feature specs
RAILS_ENV=test bundle exec turbo_tests -n 4 {,modules/*/}spec/features/**/*_spec.rb
```

CI additionally passes `--runtime-log` to balance the spec files across processes by their recorded run time.

### Running specific tests

If you want to run specific tests (e.g., only those from the team planner module), pass their paths:

```shell
RAILS_ENV=test bundle exec turbo_tests -n 4 modules/team_planner/spec
```

## Automatically run tests when files are modified

To run tests automatically when a file is modified, you can use [watchexec](https://github.com/watchexec/watchexec) like this:

```shell
watchexec --exts rb,erb -- bin/rspec spec/some/path/to/a_particular_spec.rb
```

This command instructs `watchexec` to watch `.rb` and `.erb` files for modifications in the current folder and its subfolders. Whenever a file modification is reported, the command `bin/rspec spec/some/path/to/a_particular_spec.rb` will be executed.

Stop `watchexec` by pressing `Ctrl+C`.

Set an alias to make it easier to call:

```shell
alias wrspec='watchexec --exts rb,erb -- bin/rspec'

wrspec spec/some/path/to/a_particular_spec.rb
```

To easily change the RSpec examples being run without relaunching `watchexec` every time, you can focus a particular example or example group with `focus: true`, `fit`, `fdescribe`, and `fcontext`. More details available on [RSpec documentation](https://rspec.info/features/3-12/rspec-core/filtering/filter-run-when-matching/).

## Manual acceptance tests

- Sometimes you want to test things manually. Always remember: If you test something more than once, write an automated test for it.

### Accessing a local OpenProject instance from a VM or mobile phone

See [Access the development server from another device](../../development-environment/common-setup/#access-the-development-server-from-another-device).

### LDAP tests

LDAP specs (the `with temporary LDAP` shared context) start an embedded LDAP server with [ladle](https://github.com/NUBIC/ladle), loading the fixtures from `spec/fixtures/ldap`. Ladle runs ApacheDS internally, so these specs need Java installed.

## Running tests locally in Docker

Most of the above applies to running tests locally, with some docker specific setup changes that are discussed [in the
docker development documentation](../../development-environment/docker).

## Shared spec contexts

`spec/support/shared/` holds RSpec shared contexts for setup that several specs need. Pull one in with `include_context "<name>"` or the metadata tag noted below. Two of them change how the database or the settings registry behave, so choose deliberately:

- `with real database commits` commits every write instead of running the example inside a rolled-back transaction, so threads, advisory locks and background workers can see each other's rows. Use it only for genuine concurrency specs. Every table is truncated after each example (the settings rows are restored), so the spec must create all data it needs, must not rely on shared fixtures and must stop any workers before it ends.
- `with settings reset` (metadata tag `:settings_reset`) snapshots `Settings::Definition` before the example group and restores it after each example. Use it when a spec adds, resets or overrides definitions or stubs `configuration.yml`. A spec that only needs a different setting value should use the `with_settings: { ... }` metadata instead, which stubs `Setting[]` without touching the definitions.

## Generators

In order to support developer productivity and testing confidence, we've extracted out common setup and boilerplate for good tests
as RSpec generators and are encouraged to use them when adding a new spec file in OpenProject.

To see the list of available RSpec generators, run:

```shell
./bin/rails generate -h
```

You'll see them under the "OpenProject" generator namespace.

Along with the generators, we've bundled some helpful **USAGE** guides for each to help get up and running with them. Accessing them is as simple as:

```shell
./bin/rails generate open_project:rspec:GENERATOR_NAME -h
```
