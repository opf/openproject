<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2014 the OpenProject Foundation (OPF)

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

## Cucumber

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

### Shortcuts

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

### JavaScript and Firebug

To activate selenium as test driver to test javascript on web pages, you can add
@javascript above the scenario like the following example shows:

    @javascript
    Scenario: Testing something with Javascript
      When I ...

You can always start a debugger using the step "And I start debugging".
If you need Firebug and Firepath while debugging a scenario, just replace
@javascript with @firebug.


## Running tests with Karma

To run JavaScript tests, first ensure you have Karma and all necessary
dependencies installed via npm (i.e. `npm install`). If you want a single test
run, use the standard npm command:

    npm test

By default tests will be run with PhantomJS and Firefox. To start a server or for
more options (such as another Browsers), invoke the Karma command directly. e.g.

    ./node_modules/karma/bin/karma start
    ./node_modules/karma/bin/karma start --browsers Chrome,Firefox

## RSpec

You can run the specs with the following commands:

* `bundle exec rake spec` Run all core specs with a random seed
* `SPEC_OPTS="--seed 12935" bundle exec rake spec` Run the core specs with the seed 12935

TODO: how to run plugins specs.

## Test Unit

You can run a single test with the following command:

* ``rake test:units TEST=path/to/test.rb TESTOPTS="--name=test_name_of_test_to_run"``

You let test unit display test names instead of anonymous dots with the following command:

* ``rake test:units TESTOPTS="--verbose=verbose"``

## For the fancy programmer

* We are testing on travis-ci. Look there for your pull requests.<br />
  https://travis-ci.org/opf/openproject
* If you have enabled the terminal bell, add `; echo -e "\a"` to the end of your test command. The terminal bell will then tell you when your tests finished.


## Manual acceptance tests

* Sometimes you want to test things manually. Always remember: If you test something more than once, write an automated test for it.
* Assuming you do not have a version of Internet Explorer already installed on your computer, you can grab a VM with preinstalled IE's directly from Microsoft: http://www.modern.ie/en-us/virtualization-tools#downloads
