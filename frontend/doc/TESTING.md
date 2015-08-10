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

It does not offer real End to End (E2E) Testing,a s there is currently no way to start up the whole application beforehand, so the suite uses a mock server to test each component independently and in the context of a page.

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

Configuration is done in `/frontend/tests/integration/protractor.conf.js`. The only usable browser right now for protractor is Firefox. That is, you can change your browser locally to Chrome if you want to, however, TravisCI so far only supports running tests via Firefox.

## Capybara/Cucumber/RSpec E2E Testing

The heavy lifting is done via these Testsuites, which are tightly integrated with the Rails stack (and not even part of the `./frontend` folder). Most of the actually test Rails view, but there are a few exceptions, such as the tests in `./spec/features/work_packages/details` which test a good deal of features related to the Work Package Details pane.

