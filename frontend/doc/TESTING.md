Testing the Frontend
====================

Tests are divided into three categories;

1. Karma based unit tests (AngularJS components only, standalone)
2. Capybara/Cucumber/RSpec based tests (feature based and spec based, require the full Rails)

All of these are currently run on TravisCI for each push and each Pull Request.

## Karma Unit tests

__Note__: the default browser for testing is [PhantomJS](http://phantomjs.org). The configuration for all of this can be found at `/frontend/karma.conf.js`.

All test files for `karma` live in `./frontend/tests/unit/tests`. There are some `factories` and `mocks` present, which at some point in time were usable via [`rosie.js`](https://github.com/bkeepers/rosie).

Karma unit tests can be executed via

```
./frontend/node_modules/.bin/karma start
```

Optionally, if more than the default browser should be used, a `--browsers` flag can be passed:

```
./frontend/node_modules/.bin/karma start --browsers PhantomJS,Firefox
```

By default, this command will wait and watch the test files and run the tests again if something changes. If only one run is required, use a `--single-run` flag.

You may also want to use `npm` from the project root:

```bash
# shorthand for ./frontend/node_modules/.bin/karma start --browsers PhantomJS,Firefox --single-run
$ npm karma
```

The tests use [`mocha`](https://mochajs.org/) for it's test syntax. With a syntax looking like this:

```javascript
describe('my new feature', function() {
  /* tests */
});
```

Individual parts of the test suite can easily be run independently from the suite by adding `.only` to the DSLs constructs (`describe`, `context`, `it`):

```javascript
describe.only('my new feature', function() {
  /* tests */
});
```

### Note on Templates

The karma runner uses a plugin to precompile the templates for directive tests called [`ngHtml2JsPreprocessor`](https://github.com/karma-runner/karma-ng-html2js-preprocessor) to avoid problems when testing directives in isolation from the rest of the other modules.

## Capybara/Cucumber/RSpec E2E Testing

The heavy lifting is done via these Testsuites, which are tightly integrated with the Rails stack (and not even part of the `./frontend` folder). Most of them actually test Rails views, but there are a few exceptions: The specs in `./spec/features/work_packages/details` test a good deal of features related to the Work Package Details pane.

## A note on plugins & commands used

Some of the plugins provide integration tests based on RSpec, Capybara and cucumber. To run the tests of a plugin, the core is required.

### Example: `openproject-plugin`

Assumptions:

- The plugin `openproject-plugins` exists on your local file system, parallel to a clone of `openproject`
- The plugin contains a `spec` folder and spec that form a suite to testing the plugin
- The plugin is installed into the Installation of OpenProject located in `openproject`

__Note:__ For installing OpenProject plugins, please refer to `./doc/DEVELOP_PLUGINS.md`

To run specs for a given plugin:

```bash
$ pwd
/home/user/code/openproject
$ rspec ../openproject-plugin/spec
```

Same with cucumber:

```bash
$ pwd
/home/user/code/openproject
$ cuke ../openproject-plugin/features
```

__Note:__ `cuke` is a very useful shorthand for:

```bash
function cuke() {
  bundle exec rake cucumber:custom["$1"]
}
```

There are (in older branches) some legacy tests that might have to be executed,which can be done via:

```bash
$ pwd
/home/user/code/openproject
$ rake test:units TEST=../openproject-plugin/test
```

These older legacy tests have been migrated for version `4.1`, but can still popup in some older plugins, or even an old version of OpenProject. the legacy tests have been converted by `@myabc` via gem and are located (for newer versions) here: `./spec/legacy/`. These should be removed in the future an be replaced by either proper specs or even complete features.
