# Handling flaky tests

## What is a flaky spec?

A flaky spec is a test that produces inconsistent results across runs under identical circumstances: sometimes it passes, sometimes it fails. This is most often observed in CI runs.

Flaky tests must be avoided because they weaken the confidence in the testing results. Failing CI runs have to be checked to assess if the failures are real failures or simply false positives.

To restore confidence in the testing results, flaky tests have to be stabilized. The process goes through the following steps:

1. Discovering a spec failure
2. Confirming the spec is flaky
3. Reproducing the failure locally
4. Analyzing
5. Fixing
6. Disabling the spec if fixing is not possible

## Discovering a spec failure

Developers notice a failing spec in CI runs related to the PR they are working on, or when merging a PR.

The failing spec is suspicious as it seems unrelated to the changes introduced by the commits.

Out-of-hours correlation is a lead, not proof of a datetime bug. Evening or weekend failures can still be caused by
ordinary flakiness, branch-specific regressions, or infrastructure issues. Start by separating build/setup failures from
actual `Unit tests` or `Feature tests`, then look for recurring spec names before concluding that time-sensitive logic is involved.

To get the failing spec names, use `script/github_pr_errors` and give it the URL of the failing run as argument, for example:

```bash
script/github_pr_errors https://github.com/opf/openproject/actions/runs/18215876372/job/51864889174
```

There are options to display images or display advice to reproduce the failures. Use `--help` to know more.

To aggregate recent `Test suite` failures and highlight specs that skew outside 09:00-18:00 Europe/Berlin Monday to Friday,
use:

```bash
export GITHUB_TOKEN=...
script/report_out_of_hours_ci_failures --days 30
```

The report focuses on `dev` and `release/*` runs by default and excludes failures that never reached the unit or feature test steps.

## Confirming the spec is flaky

To confirm the flakiness of the spec, either:

- Run it locally
  - If it passes when run alone => it's a flaky spec
  - If it fails, we can't tell. Run it multiple times with `script/bulk_run_rspec` which runs the given specs 5 times. Make sure it does not fail for dummy reasons (frontend not started, translations not up to date, DB not migrated, etc.)
    - If it still fails => it's a legitimate failure. The app is not behaving correctly or the test needs to be rewritten due to recent changes.
    - If it passes at least once => it's a flaky spec

- Run it in CI
  - Restart the failed workflow run; after ~20 minutes the tests will all have run again
  - If every test passes => it's a flaky spec
  - If some tests fail, but they are all different from the ones failing initially => they are all flaky specs
  - If some tests fail, and some of them are the same => the ones having failed in only one of the two runs are flaky; the others we can't say for sure (they may be legitimate failures or flaky specs).

## Reproducing the failure locally

There are greater chances to reproduce a test failure when run under the same circumstances as the CI job. Sometimes it's possible to reproduce the flakiness easily, but that's not always the case.

A good strategy is to try running the test normally first. If you can't reproduce the failure, make your environment closer to the CI environment and try again. Repeat until you manage to reproduce it.

Strategy also varies if it's a unit or a feature test: for instance test order is most often the cause of flaky unit tests, while for feature tests conditions related to execution speed and race conditions are more likely to reproduce the failures.

Use `script/github_pr_errors --display-rerun-info` as it will give you both the commands to checkout the correct commit, and the command to rerun the spec group that failed with the correct seed. Feel free to extend that script with anything you deem useful.

Use `script/bulk_run_rspec` to run the same spec multiple times. Most of the time, it fails at least once.

Below are listed some conditions to help reproducing a failure, from most efficient to less efficient for feature tests.

### Use eager loading

To be closer to production, CI eager loads the application. As it takes 3 to 5 seconds, this is not done by default when developing.

Some behavior may change because a class or a monkey-patch is loaded / not loaded.

Use
```shell
export CI=true
```

Or alternatively if you want to avoid other side-effects from `CI=true`, use

```shell
export EAGER_LOAD=1
```

This `CI=true` is given by `script/github_pr_errors --display-rerun-info`.

### Use the same merge commit

For pull requests, the commit of the PR branch is merged into the head commit of the target branch before running the tests. This information is given in the CI run, in the "Run actions/checkout" step, under the "Checking out the ref" paragraph.

It looks like this: `HEAD is now at 52dd921c Merge 438daa2353d74f5a6afe5bf03af4e298b97a365d into e63289cc26cdb6f675c23fe26dfc4f0de9b8c8d6`.

The format is "Merge \<pr commit\> into \<target branch commit\>", so checkout `<target branch commit>` in detached HEAD, then merge `<pr commit>` to run the exact same code as CI.

This information is given by `script/github_pr_errors --display-rerun-info`.

### Run headless and headful

(feature tests only)

Sometimes, browser behavior varies between headless and headful.

Use `OPENPROJECT_TESTING_NO_HEADLESS=1` to run headful, and `unset OPENPROJECT_TESTING_NO_HEADLESS` to run headless (default).

### Stress load your computer

On CI, tests are run in parallel in ~32 processes (1 process per CPU), and as many browser instances and databases. This results in slower executions than running a test in isolation, and this slowdown can cause synchronization issues and failures.

Use a stress tool utility. `s-tui` works reasonably well with macOS ([`s-tui` homepage](https://amanusk.github.io/s-tui/)).

## Use same set of test files and same test seed

Some tests may leak state after being run, leading to subsequent tests behaving differently and failing:
- OpenProject code uses memoization and caching for performance, and cache is not cleared after test, making next test start with polluted cache.
- Some tests monkey-patch OpenProject code, but don't restore behavior correctly.

As the tests are split randomly between the parallel processes, it's important to run with the exact same files.

As the order of tests is different for each run, it's important to run the failing test with the same seed.

This information can be found in the log output. It is also given by `script/github_pr_errors --display-rerun-info` which reads this output and extracts the relevant information.

If it fails when run with its group, but not when run alone, then the test failure is order-dependent.


### Use fresh database structure

If switching a lot between branches during development and migrating databases each time, the test database may be a bit ahead of time compared to the one used on CI (for example, because you used `dev` previously and now run a test on a 2-month old branch).

Reset the test database to its pristine state:
```shell
bin/rails db:drop db:create db:migrate RAILS_ENV=test
```

The test database can be safely reset because it does not contain any data.

### Use UTC timezone

Some behavior depend on the time zone. CI uses UTC by default.

```shell
export TZ=UTC
```

This `TZ=UTC` is given by `script/github_pr_errors --display-rerun-info`.

### Use `info` logging level

Using log level `debug` will output more information and run the test slower than on CI.

```shell
export OPENPROJECT_LOG__LEVEL=info
```

### Clear custom configuration

Avoid having custom `OPENPROJECT_XXX` variables in `.env` files, or a `test:` section in the `config/configuration.yml` file that would override some default OpenProject settings and alter default behavior.

### Use many Puma threads (0:4)

Locally you may use only one thread with `CAPYBARA_PUMA_THREADS="1:1"` because it makes it easier to debug with `binding.irb`. But CI uses the default Capybara settings for Puma: 0 threads min and 4 threads max.

Using 0:4 threads can trigger some concurrency issues that only occur if requests are processed in parallel.

```shell
export CAPYBARA_PUMA_THREADS=0:4
```

or

```shell
unset CAPYBARA_PUMA_THREADS
```

Running test like this with multiple threads can make it complicated to use `binding.irb`, but it can be necessary to reproduce the failure. Try this last if you rely on `binding.irb`.

### Do not use Spring

Spring preloads stuff and makes things more complicated to reproduce.

```shell
spring stop
export DISABLE_SPRING=1
```

### Precompile assets

CI does not run a frontend proxy: it precompiles assets. While differences are rare, it is closer to CI to precompile assets as well.

```shell
bin/rails assets:clobber openproject:plugins:register_frontend assets:precompile
export OPENPROJECT_DISABLE_DEV_ASSET_PROXY=1
```

### Install third-party binaries: svnadmin, git, java

Some tests have external dependencies:
  - Source control management tests need `svnadmin` and `git` binaries.
  - LDAP tests need `java` to spin up an LDAP server.

### Use correct Chrome and Webdriver versions

Versions are output in the log like `Session info: chrome=141.0.7390.107`.

Selenium Manager can be used to download some browsers.

```shell
$(bundle show selenium-webdriver)/bin/macos/selenium-manager --browser chrome
```

Use options `--driver-version`, `--browser-version`, and `--skip-browser-in-path`.


## Analyzing

### Unit test

For a unit test, it's almost always a matter of order. If it fails when run with its group, but not when run alone, then it's order-dependent.

If it's order-dependent, RSpec has the `--bisect` option: it will run the suite multiple times, with different examples each time, until it finds a minimal reproduction set. Once you have that minimal reproduction set, it's easier to find what's going wrong.

Once you have a minimal reproduction set, find what in the first test makes the second one fail. The first test is probably leaking state somewhere.

Try deleting some parts of the first test (setup or test body) and rerun until you have no failures anymore. Then reintroduce code until you find which part is causing the flakiness.

### Examples of past flaky unit tests

- hardcoded id in expectations: https://github.com/opf/openproject/commit/02deb080e48
- bad reloading of a `shared_let`: https://github.com/opf/openproject/commit/51330bf7a81
- background jobs still in the queue executed at next test: https://github.com/opf/openproject/commit/a8e9acf9b7d
- wrong type being used in work package factory: https://github.com/opf/openproject/commit/fd24cc538d8
- ...

Get flaky fixes with:

```bash
git log --grep=flaky --no-merges
```

### Feature test

It's often a matter of the browser not waiting long enough before doing an action, and then having this action discarded because some JavaScript updates the page.

For instance, the test clicks on the relation tab and creates a child work package, then immediately clicks the context menu of another relation to do an action. And that fails. It's possible that creating the child work package initiated a reload of the relations tab; a while after the context menu is opened, the response of that request comes and the relation tab is repainted, closing the context menu. Clicking the action will then fail.

Most of the time, some elements are displayed or change only once the request has finished, so make the test wait until these elements are displayed. The simplest is when a spinner is visible: just wait for the spinner to disappear.

If it's about the creation or update of an object, helpers like `expect_and_dismiss_flash(message: "Successful update.")` work well.

You'll have to try and set breakpoints to manually interact with the page and understand what could be going wrong.

Use `binding.irb` to set breakpoints in Ruby. Use `CAPYBARA_PUMA_THREADS="1:1"` to have only one Puma thread so that the whole server stops when there is a breakpoint in the controller.

If you have a `binding.irb` in the server code, the test code might eventually exit because of a Capybara expectation timing out. When that's the case, use a `sleep(10000)` in the test code to have proper time to test things out in the server code. It's a bit complicated to stop that timeout but often worth it.

Use `debugger` to set breakpoints in JavaScript code. Then use `OPENPROJECT_TESTING_AUTO_DEVTOOLS=1` to automatically open DevTools when the browser opens. Without DevTools open, the breakpoints will not work. That also helps seeing the network requests being sent.

If using debugger is not possible, use `console.log` and `puts` to display debugging information, and take browser screenshots with `puts Capybara::Screenshot.screenshot_and_save_page`.

Browser screenshots are automatically taken on feature test failure when possible, use `script/github_pr_errors --images` to get them.

If the interactions are too fast to understand why the test is failing, use `OPENPROJECT_TESTING_SLOWDOWN_FACTOR`, providing the number of seconds to slow down every browser command with. For example, to slow down every interaction by 200 milliseconds, run with `OPENPROJECT_TESTING_SLOWDOWN_FACTOR=0.2`.


### Examples of past flaky feature tests

- race condition when loading preview in data picker: https://github.com/opf/openproject/commit/d646353c338
- interacting too early with a modal which has not finished its appearing animation: https://github.com/opf/openproject/commit/a9d3484641d
- synchronization issue in delete storage page: https://github.com/opf/openproject/commit/7e1d6c04169
- does not wait for agenda item being created: https://github.com/opf/openproject/commit/36b9e2517f1
- drag and drop a card at wrong coordinates because cards order changes between coordinates calculation and drag-and-drop action (sync issue again): https://github.com/opf/openproject/commit/7c7ebb64587
- trying to interact with the page while it has not finished loading: https://github.com/opf/openproject/commit/e4cfb4e55c7
- information read from a non-reliable source: https://github.com/opf/openproject/commit/5776ad06bba
- ...

Get flaky fixes with:

```bash
git log --grep=flaky --no-merges
```

### Common feature-spec flake patterns and their fixes

The most frequent root cause is **Turbo's asynchronous rendering**. `wait_for_network_idle` only waits for the HTTP response to arrive, but Turbo updates the DOM *after* that:

1. HTTP response received → network idle
2. Turbo dispatches `turbo:before-stream-render` (or `turbo:before-render` for Drive)
3. Turbo awaits the next repaint
4. DOM is updated

An assertion running between steps 1 and 4 sees stale content and fails intermittently. The helpers below (in `spec/support/shared/cuprite_helpers.rb` and `spec/support/toasts/expectations.rb`) register their JS event listeners *before* yielding the block, so they are race-condition-safe. Wrap only the triggering action — never the assertion.

| Helper | Use when the action triggers… | Example |
|--------|-------------------------------|---------|
| `wait_for_turbo_stream { action }` | a **Turbo Stream** response (partial DOM replacement: dialog updates, list item changes). Waits for `op:turbo-stream-rendered`. | `wait_for_turbo_stream { share_dialog.toggle_public }` |
| `wait_for_turbo { action }` | a **Turbo Drive** navigation (form submit, POST → redirect). Waits for `turbo:load`. | `wait_for_turbo { click_on "Complete" }` |
| `wait_for_turbo_frame { action }` | a **Turbo Frame** load/update. Waits for `turbo:frame-load`. | `wait_for_turbo_frame { projects_page.remove_column("Status") }` |
| `wait_for_network_idle` | a plain AJAX/Angular request with **no** Turbo rendering to wait for. | `columns.remove("Priority"); wait_for_network_idle` |
| `dismiss_specific_toaster!(message:)` | **multiple** toasts may appear in sequence and `dismiss_toaster!` could close the wrong one. | `dismiss_specific_toaster!(message: "Saved successfully")` |
| `have_test_selector(sel, text:)` | the container itself may be **replaced** by a Turbo Stream (stale node). Re-queries the DOM on each retry, unlike `within_test_selector`. | `expect(page).to have_test_selector("agenda-items-list", text: "No notes")` |
| `retry_block { action }` | page state is **non-deterministic** after navigation (e.g. `go_back` re-initialises asynchronously). | `retry_block { click_on "Calendar event" }` |
| `have_button("Label", wait: 20)` | an Angular custom element sets its label asynchronously in `ngOnInit` and the default wait is too short on slow CI. | `expect(page).to have_button("Nextcloud login", wait: 20)` |
| `expect_active!` (not `activate!`) | a field is **already** in edit mode (e.g. auto-opened after a failed save). | `subject_field.expect_active!` |

A frequent trap: a helper method call (`field.open_field`) followed by a bare `wait_for_network_idle` on the next line. The HTTP request finishes but Turbo hasn't applied the stream yet — replace it with `wait_for_turbo_stream { field.open_field }`. Wrapping a helper that internally calls `wait_for_network_idle` is safe, because the outer listener is registered before the block runs.

To pick the right wait when unsure, check the controller action: `render turbo_stream:` / `format.turbo_stream` → `wait_for_turbo_stream`; `redirect_to` → `wait_for_turbo`; a `<turbo-frame>` update → `wait_for_turbo_frame`.

### Is the failure authentic?

Flakiness can also be reversed: a test passes sometimes, but actually, given the code state, it should always fail.

One example is https://github.com/opf/openproject/commit/8d4adcfcb22 where the test was expecting the enterprise banner to be absent. When analyzing it, we noticed that the enterprise banner was always present, and the test was passing simply because it was a bit long to load, so the absence expectation passed. Sometimes it loaded in time and the test failed.

## Fixing

If you managed to fix it, congrats 👏

Try running `script/bulk_run_rspec --run-count 10` on the fixed spec to check one last time that the issue is fixed, or at least that it fails less often than before.

In the commit message, it's important to indicate:

- The spec you fixed
  - For instance: if the fix is located in a `spec/support/pages/some_page.rb` file and the commit message only says "Fix flaky spec", that makes it harder for people 6 months later wanting to modify the method you changed or just understand it. If they don't know which test was failing, they can't run it again and may reintroduce flakiness.
- The workflow run where it failed
- The attached bug link if the test was skipped and a bug ticket was created for it.
  - Should not be needed if the `skip: "description"` contained this information.
- A description of the fix applied
  - If the fix does not work and the spec is still flaky, it will be helpful for the next developer to understand your interpretation of the failure and what you tried so that they can try something else.

## Disabling the spec if fixing is not possible

If you can't fix it, the developer is responsible for disabling the spec and creating a bug ticket for it and assigning it to the responsible team or developer and/or setting the "module" field.

Add today's date and the bug ticket number in the skip reason. That will help identify it later. For instance:

```ruby
it "does stuff", skip: "2025-10-16 - Bug #12345 - Flaky spec. Can reproduce the failure but unable to find why it does this" do
  do.this
  page.click here
  expect(page.this).to have(that)
end
```

In the bug report, indicate the flaky spec file with line number for the test that fails, and add a link to the workflow run where it has failed. This helps a lot with debugging and reproducing the failure. This saves time.
