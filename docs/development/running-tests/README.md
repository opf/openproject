<!---- copyright
OpenProject is an open source project management software.
Copyright (C) 2012-2020 the OpenProject GmbH

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

See docs/COPYRIGHT.rdoc for more details.

++-->

# Testing OpenProject

OpenProject uses automated tests throughout the stack. Tests that are executed in the browser (npm frontend, rspec integration and cucumber tests) require to have Chrome installed.

## Frontend tests

To run JavaScript frontend tests, first ensure you have all necessary
dependencies installed via npm (i.e. `npm install`).

You can run all frontend tests with the standard npm command:

    npm test
    

[For more information, check out the frontend guides](https://github.com/opf/openproject/blob/dev/frontend/doc/README.md).

## Rails backend and integration tests

### RSpec

You can run the specs with the following commands:

* `bundle exec rake spec:core` Run all core specs with a random seed
* `bundle exec rake spec:legacy` Run all legacy specs with a random seed
* `bundle exec rake spec:plugins` Run plugin specs with a random seed
* `bundle exec rake spec:all` Run core and plugin specs with a random seed
* `SPEC_OPTS="--seed 12935" bundle exec rake spec` Run the core specs with the seed 12935

### Integration tests with Capybara

We use Capybara for integration tests as rspec feature specs. They are automatically executed with Capybara when `js: true` is set.

#### Selenium, Chrome

For the javascript dependent integration tests, you have to install Chrome, to run them locally.

Capybara uses Selenium to drive the browser and perform the actions we describe in each spec. Previously, we have used Firefox as the browser driven by Selenium.

Due to flaky test results on Travis (`No output has been received in the last 10m0s`), we switched to using Chrome for the time being. Because most developers already employ Chrome while developing and Firefox ESR being another supported browser, we would have preferred to stick to Firefox for the tests and will try to do so as soon as test results become reproducible again.


**Headless mode**

Firefox tests through Selenium are run with Chrome as `--headless` by default. To override this and watch the Chrome instance set the ENV variable `OPENPROJECT_TESTING_NO_HEADLESS=1`.

### Cucumber

**Note:** *We do not write new cucumber features. The current plan is to move away from
cucumber towards regular specs using Capybara. For the time being however, please keep the existing
cucumber features green but write feature specs in Capybara for any code that is not already
covered by cucumber.*

The cucumber features can be run using rake. You can run the following
rake tasks using the command `bundle exec rake <task>`.

* `cucumber` Run core features
* `cucumber:plugins` Run plugin features
* `cucumber:all` Run core and plugin features
* `cucumber:custom[features]`: Run single features or folders of features

    Example: `cucumber:custom[features/issues/issue.feature]`
    * When providing multiple features, the task name and arguments must
      be enclosed in quotation marks.

      Example: `bundle exec rake "cucumber:custom[features/issues features/projects]"`
      
    In some development environments you might need to run single features differently as the former example results in weird error messages.
    
    `RAILS_ENV=test bundle exec cucumber -r features <path-to-feature-file> `


`cucumber:plugins` and `cucumber:all` accept an optional parameter which
allows specifying custom options to cucumber. This can be used for
executing scenarios by name, e.g. `"cucumber:all[-n 'Adding an issue link']"`.
Like with spaces in `cucumber:custom` arguments, task name and arguments
have to be enclosed in quotation marks.

#### Running cucumber features without rake

Running cucumber features without going through `rake` is possible by using
the following command

`cucumber -r features features/my/path/to/cucumber.feature`

It is also possible to run a certain cuke by passing a line number:

`cucumber -r features features/my/path/to/cucumber.feature:123`

You may also run cukes within a certain folder:

`cucumber -r features features/my/path`

**Note: `-r features` is required otherwise the step definitions cannot be found.**

You can run cucumber without rake, and with all core and plugin features included
through:

```
./bin/cucumber features/my/path/to/cucumber.feature:123
```


#### Shortcuts

Here are two bash functions which allow using shorter commands for running
cucumber features:

    # Run OpenProject cucumber features (like arguments to the cucumber command)
    # Example: cuke features/issues/issue.feature
    cuke() { RAILS_ENV=test bundle exec rake "cucumber:custom[$*]"; }

    # Run OpenProject cucumber scenarios by name
    # Example: cuken Adding an issue link
    cuken() { RAILS_ENV=test bundle exec rake "cucumber:all[-n '$*']"; }

Setting `RAILS_ENV=test` allows the cucumber rake tasks to run the features
directly in the same process, so this reduces the time until the features are
running a bit (5-10 seconds) due to the Rails environment only being loaded
once.

#### Selenium

To activate selenium as test driver to test javascript on web pages, you can add
`@javascript above the scenario like the following example shows:

    @javascript
    Scenario: Testing something with Javascript
      When I ...

#### Debugging

You can always start a debugger using the step "And I start debugging".

### Parallel testing

Running tests in parallel makes usage of all available cores of the machine.
Functionality is being provided by [parallel_tests](https://github.com/grosser/parallel_tests) gem.
See the github page for any options like number of cpus used.

#### Prepare

Adjust `database.yml` to use different databases:

```yml
test: &test
  database: openproject_test<%= ENV['TEST_ENV_NUMBER'] %>
  # ...
```

Create all databases: `rake parallel:create`

Prepare all databases:

`RAILS_ENV=test parallel_test -e "rake db:drop db:create db:migrate"`

**Note: Until `rake db:schema:load` works we have to use the command above. Then we
can use `rake parallel:prepare`**

You may also just dump your current schema with `rake db:schema:dump` (db/schema.rb)
is not part of the repository. Then you can just use `rake parallel:prepare` to prepare
test databases.

#### RSpec legacy specs

Run all legacy specs in parallel with `rake parallel:spec_legacy`

Or run them manually with `parallel_test -t rspec -o '-I spec_legacy' spec_legacy`

#### RSpec specs

Run all specs in parallel with `rake parallel:spec`

Or run them manually with `parallel_test -t rspec spec`.

#### Cucumber

Run all cucumber features in parallel with `rake parallel:cucumber`.

Or run them manually with `parallel_test -t cucumber -o '-r features' features`.

**Note:** there is also a official rake task to run cucumber features but the OpenProject cucumber
test suite requires `-r features` to run correctly. This needs to be passed to the command
thus it looks not very handy `rake parallel:features\[,,"-r features"\]`
(this is zsh compatible, command takes three arguments but we just want to pass the last one here.)

#### Plugins

Run specs for all activated plugins with `rake parallel:plugins:spec`.

Run cucumber features for all activated plugins with `rake parallel:plugins:cucumber`.

#### Full test suite

You may run all existing parts of OpenProject test suite in parallel with
`rake parallel:all`

**Note:** This will run core specs, core cucumber features, core legacy specs,
plugin specs and plugin cucumber features. This task will take around 40 minutes
on a machine with 8 parallel instances.

## For the fancy programmer

* We are testing on travis-ci. Look there for your pull requests.<br />
  https://travis-ci.org/opf/openproject
* If you have enabled the terminal bell, add `; echo -e "\a"` to the end of your test command. The terminal bell will then tell you when your tests finished.


## Manual acceptance tests

* Sometimes you want to test things manually. Always remember: If you test something more than once, write an automated test for it.
* Assuming you do not have a version of Edge already installed on your computer, you can grab a VM with preinstalled IE's directly from Microsoft: http://www.modern.ie/en-us/virtualization-tools#downloads

If you want to access the development server of OpenProject from a VM,
you need to work around the CSP `localhost` restrictions.


### Old way, fixed compilation

One way is to disable the Angular CLI that serves some of the assets when developing. To do that, run

```bash

# Precompile the application
./bin/rails assets:precompile

# Start the application server while disabling the CLI asset host 
OPENPROJECT_CLI_PROXY='' ./bin/rails s -b 0.0.0.0 -p 3000
```

Now assuming networking is set up in your VM, you can access your app server on `<your local ip>:3000` from it.

### New way, with ng serve

**The better way** when you want to develop against Edge is to set up your server to allow the CSP to the remote host.
Assuming your openproject is served at `<your local ip>:3000` and your ng serve middleware is running at `<your local ip>:4200`,
you can access both from inside a VM with nat/bridged networking as follows:

```bash
# Start ng serve middleware binding to all interfaces
npm run serve-public

# Start your openproject server with the CLI proxy configuration set
OPENPROJECT_CLI_PROXY='http://<your local ip>:4200' ./bin/rails s -b 0.0.0.0 -p 3000

# Now access your server from http://<your local ip>:3000 with code reloading
```

## Legacy LDAP tests

OpenProject supports using LDAP for user authentications.  To test LDAP
with OpenProject, load the LDAP export from test/fixtures/ldap/test-ldap.ldif
into a testing LDAP server.  Test that the ldap server can be accessed
at 127.0.0.1 on port 389.

Setting up the test ldap server is beyond the scope of this documentation.
The OpenLDAP project provides a simple LDAP implementation that should work
good as a test server.
