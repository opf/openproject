<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2015 the OpenProject Foundation (OPF)

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

See doc/COPYRIGHT.rdoc for more details.

++-->

# Testing OpenProject

OpenProject uses automated tests throughout the stack.

## Frontend tests

To run JavaScript frontend tests, first ensure you have all necessary
dependencies installed via npm (i.e. `npm install`).

You can run all frontend tests with the standard npm command:

    npm test

### Running unit tests with Karma

If you want a single test run, you can use `npm run`:

    npm run karma

By default tests will be run with PhantomJS and Firefox. To start a server or
for more options, such as another browser, invoke the karma executable directly:

    ./node_modules/karma/bin/karma start
    ./node_modules/karma/bin/karma start --browsers Chrome,Firefox

## Rails backend and integration tests

### RSpec

You can run the specs with the following commands:

* `bundle exec rake spec:core` Run all core specs with a random seed
* `bundle exec rake spec:legacy` Run all legacy specs with a random seed
* `bundle exec rake spec:plugins` Run plugin specs with a random seed
* `bundle exec rake spec:all` Run core and plugin specs with a random seed
* `SPEC_OPTS="--seed 12935" bundle exec rake spec` Run the core specs with the seed 12935

### Cucumber

**Note:** *We do not write new cucumber features. The current plan is to move away from
cucumber towards regular specs using Capybara. For the time being however, please keep the existing
cucumber features green or write your feature specs in Capybara for any  code that is not already
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

#### JavaScript and Firebug

To activate selenium as test driver to test javascript on web pages, you can add
@javascript above the scenario like the following example shows:

    @javascript
    Scenario: Testing something with Javascript
      When I ...

You can always start a debugger using the step "And I start debugging".
If you need Firebug and Firepath while debugging a scenario, just replace
@javascript with @firebug.

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
* Assuming you do not have a version of Internet Explorer already installed on your computer, you can grab a VM with preinstalled IE's directly from Microsoft: http://www.modern.ie/en-us/virtualization-tools#downloads


## Legacy LDAP tests

OpenProject supports using LDAP for user authentications.  To test LDAP
with OpenProject, load the LDAP export from test/fixtures/ldap/test-ldap.ldif
into a testing LDAP server.  Test that the ldap server can be accessed
at 127.0.0.1 on port 389.

Setting up the test ldap server is beyond the scope of this documentation.
The OpenLDAP project provides a simple LDAP implementation that should work
good as a test server.
