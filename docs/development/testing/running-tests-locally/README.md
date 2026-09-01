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

This migrates the _development_ database, outputting its schema to `db/schema.rb` and will copy this schema to the test database. This ensures your test database matches your current expected schema.

## Frontend tests

To run JavaScript frontend tests, first ensure you have all necessary dependencies installed via npm (i.e. `npm install`).

You can run all frontend tests with the standard npm command:

```shell
npm test
```

Alternatively, when in the `frontend/` folder, you can also use the watch mode of Angular to automatically run tests after you changed a file in the frontend.

```shell
./node_modules/.bin/ng test --watch
```

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

System tests are also called _rspec feature specs_ and use [Capybara](https://rubydoc.info/github/teamcapybara/capybara/master) and [Selenium](https://www.selenium.dev/documentation/webdriver/) to run. They are automatically executed with an actual browser when `js: true` is set.

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

### Dependencies

For the javascript dependent integration tests, you have to install Chrome and Firefox, to run them locally.

Capybara uses Selenium to drive the browser and perform the actions we describe in each spec. We have tests that mostly depend on Chrome and Chromedriver, but some also require specific behavior that works better in automated Firefox browsers.

### Running system tests

Almost all system tests depend on the browser for testing, you will need to have the Angular CLI running to serve frontend assets.

So with `npm run serve` running and completed in one tab, run the test using `rspec` as for the unit tests:

```shell
RAILS_ENV=test bundle exec rspec ./modules/documents/spec/features/attachment_upload_spec.rb[1:1:1:1]
```

The tests will generally run a lot slower due to the whole application being run end-to-end, but these system tests will provide the most elaborate tests possible.

You can also run _all_ feature specs locally with this command. This is not recommended due to the required execution time. Instead, prefer to select individual tests that you would like to test and let GitHub Actions CI test the entire suite.

```shell
RAILS_ENV=test bundle exec rake parallel:features -- --group-number 1 --only-group 1
```

#### WSL2

In case you are on Windows using WSL2 rather than Linux directly, running tests this way will not work. You will see an error like "Failed to find Chrome binary.". The solution here is to use Selenium Grid.

**1) Download the chrome web driver**

You can find the driver for your Chrome version [here](https://chromedriver.chromium.org/downloads)

**2) Add the driver to your `PATH`**

Either save the driver under `C:\Windows\system32` to make it available or add its alternative location to the `PATH` using the system environment variable settings ([press the WIN key and search for 'system env').

**3) Find out your WSL ethernet adapter IP**

You can do this by opening a powershell and running ``wsl cat /etc/resolv.conf `| grep nameserver `| cut -d ' ' -f 2``. Alternatively looking for the adapter's IP in the output of `ipconfig` works too.
It will be called something like "Ethernet adapter vEthernet (WSL)".

**4) Download Selenium hub**

Download version 3.141.59 (at the time of writing) [here](https://www.selenium.dev/downloads/)

The download is a JAR, i.e. a Java application. You will also need to download and install a Java Runtime Environment in at least version 8 to be able to run it.

**5) Run the Selenium Server**

In your powershell on Windows, find the JAR you downloaded in the previous step and run it like this:

```shell
java -jar .\Downloads\selenium-server-standalone-3.141.59.jar -host 192.168.0.216
```

Where `192.168.0.216` is your WSL IP from step 3).

**6) Setup your test environment**

Now you are almost ready to go. All that you need to do now is to set the necessary environment
for the browser on Windows to be able to access the application running on the Linux host.
Usually this should work transparently but it doesn't always. So we'll make sure it does.

Now in the linux world do the following variables:

```shell
export RAILS_ENV=test
export CAPYBARA_APP_HOSTNAME=`hostname -I`
export SELENIUM_GRID_URL=http://192.168.0.216:4444/wd/hub
```

Again `192.168.0.216` is the WSL IP from step 3). `hostname -I` is the IP of your Linux host seen from within Windows.
Setting this make sure the browser in Windows will try to access, for instance `http://172.29.233.42:3001/` rather than `http://localhost:3001` which may not work.

**7) Run the tests**

Now you can run the integration tests as usual as seen above. For instance like this:

```shell
bundle exec rspec ./modules/documents/spec/features/attachment_upload_spec.rb[1:1:1:1]
```

There is no need to prefix this with the `RAILS_ENV` here since we've exported it already before.

### Headless testing

Firefox tests through Selenium are run with Chrome as `--headless` by default. This means that you do not see the browser that is being tested. Sometimes you will want to see what the test is doing to debug. To override this behavior and watch the Chrome or Firefox instance set the ENV variable `OPENPROJECT_TESTING_NO_HEADLESS=1`.

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

## Parallel testing

Running tests in parallel makes usage of all available cores of the machine.
Functionality is being provided by [parallel_tests](https://github.com/grosser/parallel_tests) gem.
See its GitHub page for any options like number of cpus used.

### Prepare

By default, `parallel_test` will use CPU count to parallelize. This might be a bit much to handle for your system when 8 or more parallel browser instances are being run. To manually set the value of databases to create and tests to run in parallel, use this command:

```shell
export PARALLEL_TEST_PROCESSORS=4
```

Adjust `database.yml` to use different databases:

```yaml
test: &test
  database: openproject_test<%= ENV['TEST_ENV_NUMBER'] %>
  # ...
```

Create all databases: `RAILS_ENV=test ./bin/rails parallel:create db:migrate parallel:prepare`

Prepare all databases:

First migrate and dump your current development schema with `RAILS_ENV=development ./bin/rails db:migrate db:schema:dump` (will create a db/structure.sql)

Then you can just use `RAILS_ENV=test ./bin/rails parallel:prepare` to prepare test databases.

### RSpec specs

Run all unit and system tests in parallel with `RAILS_ENV=test ./bin/rails parallel:spec`

### Running specific tests

If you want to run specific tests (e.g., only those from the team planner module), you can use this command:

```shell
RAILS_ENV=test bundle exec parallel_rspec -- modules/team_planner/spec
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

If you want to access the development server of OpenProject from a VM or your mobile phone, you need to work around the
CSP `localhost` restrictions.

### Old way, fixed compilation

One way is to disable the Angular CLI that serves some of the assets when developing. To do that, run

```shell
# Precompile the application assets
./bin/rails openproject:plugins:register_frontend assets:precompile

# Start the application server while disabling the CLI asset host
OPENPROJECT_CLI_PROXY='' ./bin/rails s -b 0.0.0.0 -p 3000
```

Now assuming networking is set up in your VM, you can access your app server on `<your local ip>:3000` from it.

### New way, with ng serve

**The better way** when you want to develop against your local setup is to set up your server to allow the CSP to the
remote host.
Assuming your openproject is served at `<your local ip>:3000` and your ng serve middleware is running at `<your local ip>:4200`,
you can access both from inside a VM with nat/bridged networking as follows:

```shell
# Start ng serve middleware binding to the interface given by FE_HOST or on localhost if not defined
FE_HOST=<your local IP address> PROXY_HOSTNAME=<your local IP address> npm run serve
```

On npm run serve, you want to ensure it logs the correct hostname:

```log
** Angular Live Development Server is listening on <you local IP address>:4200, open your browser on http://<you local IP address>:4200/assets/frontend **
```

```shell
# Start your openproject server with the CLI proxy configuration set
OPENPROJECT_DEV_EXTRA_HOSTS=<your local IP address> OPENPROJECT_HOST_NAME=<your local IP address> OPENPROJECT_CLI_PROXY='http://<your local ip>:4200' ./bin/rails s -b 0.0.0.0 -p 3000

# Now access your server from http://<your local ip>:3000 with code reloading
```

You can also add the environment variables directly to the `.env` file and just run `./bin/rails s -b 0.0.0.0 -p 3000`. Ensure `OPENPROJECT_HTTPS` is set to `false`.

```env
LOCAL_IP_ADDR='192.168.x.y'
OPENPROJECT_DEV_EXTRA_HOSTS=$LOCAL_IP_ADDR
OPENPROJECT_HTTPS=false
OPENPROJECT_HOST_NAME=$LOCAL_IP_ADDR
OPENPROJECT_CLI_PROXY="http://$LOCAL_IP_ADDR:4200"
```

### Legacy LDAP tests

OpenProject supports using LDAP for user authentications. To test LDAP
with OpenProject, load the LDAP export from `test/fixtures/ldap/test-ldap.ldif`
into a testing LDAP server. Test that the ldap server can be accessed
at 127.0.0.1 on port 389.

Setting up the test ldap server is beyond the scope of this documentation.
The Apache DS project provides a simple LDAP implementation that should work
good as a test server.

## Running tests locally in Docker

Most of the above applies to running tests locally, with some docker specific setup changes that are discussed [in the
docker development documentation](../../development-environment/docker).

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
