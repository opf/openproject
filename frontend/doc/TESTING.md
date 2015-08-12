Testing the Frontend
====================

Tests are divided into three categories;

1. Karma based unit tests (AngularJS components only, standalone)
2. protractor and mock based integration testing (AngularJS components only, standalone)
3. Capybara/Cucumber/RSpec based tests (feature based and spec based, require the full Rails)

All of these are currently run on TravisCI for each push and each Pull Request.

## Karma Unit tests

__Note__: the default browser for testing is [PhantomJS](http://phantomjs.org). The configuration for all of this can be found at `/frontend/karma.conf.js`.

All test files for `karma` live under `./frontend/tests/unit/tests`. There are some `factories` and `mocks` present, which at some point in time were usable via `rosie.js`.

Karma unit tests can be executed via

```
./frontend/node_modules/.bin/karma start
```

Optionally, if more than the default browser should be used, a `--browsers` flag can be passed:

```
./frontend/node_modules/.bin/karma start --browsers PhantomJS,Firefox
```

By default, this command will wait and watch the test files and run the tests again, if something changes. If only one run is required, use a `--single-run` flag.

You may also want to use `npm` from the project root:

```
npm karma
```

The tests use [`mocha`](https://mochajs.org/) for it's test syntax. With a syntax looking like this

```javascript
describe('my new feature', function() {
  /* tests */
})
```

individual parts of the test suite can easily be run independently from the suite by adding `.only` to the DSLs constructs (`describe`, `context`, `it`):

```javascript
describe.only('my new feature', function() {
  /* tests */
})
```

### Note on Templates

The karma runner uses a plugin to precompile the templates for directive tests called [`ngHtml2JsPreprocessor`](https://github.com/karma-runner/karma-ng-html2js-preprocessor) to avoid problems when testing directives in isolation from the rest of the other modules.

## Protractor based integration testing

__Note__: All of the test files live in `./frontend/tests/integration/specs`.

The protractor based suite offers integration tests for the Angular based views, first and foremost, the WorkPackage application. It's based on AngularJS' own [protractor library](https://github.com/angular/protractor) and therefore requires Selenium.

It does not offer real End to End (E2E) Testing,a s there is currently no way to start up the whole application beforehand, so the suite uses a mock server and mock json to test each component independently and in the context of a page.

Every command related to the suite is wrapped via `gulp`. the most interesting commands are:

- `gulp tests:protractor` - starts up a server, recompiles the codebase necessary and starts a single run via protractor.
- `gulp webdriver:*` - the webdriver tasks are in there to update the selenium server necessary to run protractor at all
- `npm protractor` - a wrapper around `gulp tests:protractor`, runnable from the project root

The `protractor` library brings it's own syntax when it comes to writing the tests themselves:

```javascript
describe('edit state', function() {
  before(function() {
    editor.$('.inplace-editing--trigger-link').click();
  });

  context('dropdown', function() {
    it('should be rendered', function() {
      expect( /* ... */
```

Tests can be focused by using `iit` (not a typo) instead of `it` and can be ignored by using `xit` instead of it.

Configuration is done in `./frontend/tests/integration/protractor.conf.js`. The only usable browser right now for protractor is Firefox. That is, you can change your browser locally to Chrome if you want to, however, TravisCI so far only supports running tests via Firefox.

The protractor suite currently only covers the work packages list and provides no integration testing for timelines and the other components (most of them are tested as collateral).

### Mocking

As the backend ist not present during testing, the protractor suite actually uses mocked json responses to facilitate the behaviour of data when testing the components.

__Note:__ All mocks are found under `./frontend/tests/integration/mocks/` and a re usually loaded via a custom function defined in the tests which wrap `WorkPackageDetailsPane`, which in turn wraps a call to `browser.get()` (see `./frontend/tests/integration/pages/work-package-details-pane.js`)

A mock usually just represents a probable json response from the backend. As the protractor suite does not use the Rails backend, this can be a source of confusion:

__Make sure you keep your mocks in sync with the current implementation of the API__. Otherwise, you will not be able to detect problems with the API and/or your component.

### Dummy servers

The protractor suite also used dummy services to mock out the endpoints of all of the APIs for mocking. these files are still found under `./frontend/tests/integration/mocks/`. These can probably be removed in future versions.

## Capybara/Cucumber/RSpec E2E Testing

The heavy lifting is done via these Testsuites, which are tightly integrated with the Rails stack (and not even part of the `./frontend` folder). Most of the actually test Rails view, but there are a few exceptions, such as the tests in `./spec/features/work_packages/details` which test a good deal of features related to the Work Package Details pane.

## A note on plugins & commands used

So far, no plugins provide an extension for the protractor suite. The protractor suite is only for the core (`opf/openproject` itself). The coverage is not complete.

However, plugins to provide some integration tests based on RSpec, Capybara and cucumber. To run the tests of a plugin, the core is required.

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

These older legacy tests have been migrated for version `4.1`, but can still popup in some older plugins, or even an old version of OpenProject. the legacy tests have been converted by @myabc via gem and are located (for newer versions) here: `./spec/legacy/`. These should be removed in the future an be replaced by either proper specs or even complete features.


