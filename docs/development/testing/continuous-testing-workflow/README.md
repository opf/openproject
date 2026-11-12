---
sidebar_navigation:
  title: Continuous testing workflow
description: Overview of the OpenProject CI pipelines on GitHub Actions and how to debug failures
keywords: testing, continuous integration, github actions, ci
---

# Continuous testing workflow

As part of the [development flow at OpenProject](../../../development/#branching-model-and-development-flow), proposed changes to the core application will be made through a GitHub pull request and the entire test suite is automatically evaluated on GitHub Actions. You will see the results as a status on your pull request.

You will likely start working with the OpenProject test suite through our continuous testing setup at [GitHub Actions](https://github.com/opf/openproject/actions). All pull requests and commits to the core repository will be tested by GitHub Actions.

Successful test suite runs are one requirement to see your changes merged.

## List failures

A failing status will look like the following on your pull request. You may need to click _Show all checks_ to expand all checks to see the details link.

![Exemplary failing github actions test suite](github-broken-tests-pr.png)

Here you'll see that the _GitHub Actions_ check has reported an error, which likely means that your pull request contains errors. It might also result from a [temporary error running the test suite](#tests-failing-on-github-actions-ci-and-passing-locally), or from a test that was broken in the `dev` branch.

The test suite is [run in parallel](../running-tests-locally/#parallel-testing) to save time. The overall run time of the test suite is around _15 minutes_ on GitHub.

Click on the Details link to see the individual _jobs_ that GitHub executes. The screenshots below show a run in which one of the feature jobs has reported an error.

![Exemplary failed status details](github-broken-tests-pr-details1.png)

Click on each job and each step to show the log output for this job. It will contain more information about how many tests failed and will also temporarily provide a screenshot of the browser during the occurrence of the test failure (only if a browser was involved in testing).

In our example, multiple tests are reported as failing:

```shell
rspec ./spec/features/work_packages/pagination_spec.rb[1:1:1:1] # Work package pagination with project scope behaves like paginated work package list is expected not to have text "WorkPackage No. 23"
rspec ./spec/features/work_packages/pagination_spec.rb[1:2:1:1] # Work package pagination globally behaves like paginated work package list is expected not to have text "WorkPackage No. 29"
rspec ./spec/features/work_packages/timeline/timeline_navigation_spec.rb:131 # Work package timeline navigation can save the open state and zoom of timeline
rspec ./spec/features/work_packages/timeline/timeline_navigation_spec.rb:193 # Work package timeline navigation with a hierarchy being shown toggles the hierarchy in both views
rspec ./spec/features/work_packages/timeline/timeline_navigation_spec.rb:317 # Work package timeline navigation when table is grouped shows milestone icons on collapsed project group rows but not on expanded ones
```

![GitHub job log showing failing test](github-broken-tests.png)

### Diagnose failures

Once you know which tests are failing, run them locally to try and reproduce the failures. Having reproducible failures locally is the first step to diagnose and fix them.

How to do this depends on the kind of job that failed.

**Errors in the _Frontend test suite_ workflow**

The _Frontend test suite_ workflow (`.github/workflows/test-frontend-unit.yml`) typechecks the frontend and runs the frontend specs in Chromium, Firefox and WebKit. An error there means you likely have broken an existing frontend spec, added an invalid new one, or introduced a type error. Please see the [Frontend tests](../running-tests-locally/#frontend-tests) section on how to run them.

**Errors in the _Units + Features_ job**

The _Test suite_ workflow (`.github/workflows/test-core.yml`) runs the RSpec suite in a single _Units + Features_ job: first the _Unit tests_ step, then the _Feature tests_ step. Please see the [Unit tests](../running-tests-locally/#unit-tests) and [System tests](../running-tests-locally/#system-tests) sections on how to run failing specs locally.

**Helper to extract all failing tests**

There is a small ruby script that will parse the logs of a GitHub Actions run and output all `rspec` tests that failed for you to run in one command.

```shell
./script/github_pr_errors
```

If you want to run the tests directly to rspec, you can use this command:

```shell
./script/github_pr_errors | xargs bundle exec rspec
```

### Tests failing on GitHub Actions CI and passing locally

Some tests can fail on GitHub actions CI, and pass locally which makes them harder to reproduce, diagnose, and fix.

To reproduce the CI environment:

- Run with `CI=true` to enable CI-specific test configuration, including eager loading.
- Compare the `OPENPROJECT_*` environment variables with those set by the failing workflow.
- Reuse the random seed from the failing job, for example `bundle exec rspec --seed 18352`. Use RSpec's `--bisect` option to investigate order-dependent failures.
- For browser failures, use `OPENPROJECT_TESTING_NO_HEADLESS=1` to [watch the browser locally](../running-tests-locally/#headless-testing).

The [workflow definitions](https://github.com/opf/openproject/tree/dev/.github/workflows) are the source for current job names, timeouts, and commands. Parallel jobs can use different random seeds; use the seed reported by the failing job.

These are flaky tests and should be fixed as soon as possible as they undermine the trust we have in our test results. [Follow our advice on handling flaky tests](../handling-flaky-tests/) for more information.

### Skip test execution on GitHub Actions CI

Sometimes, you know you're pushing changes to a pull request that you now are work in progress or are known to break existing or new tests.

To avoid additional test executions, you can include `[skip ci]` in your commit message to ensure GitHub Actions are not being triggered and skips your build. Please note that a successful merge of your pull request will require a green CI build.
