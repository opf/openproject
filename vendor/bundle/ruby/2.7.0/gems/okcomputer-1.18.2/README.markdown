[![Code Climate](https://codeclimate.com/github/sportngin/okcomputer.svg)](https://codeclimate.com/github/sportngin/okcomputer)
[![Build Status](https://travis-ci.org/sportngin/okcomputer.svg)](https://travis-ci.org/sportngin/okcomputer)
[![Coverage Status](https://coveralls.io/repos/sportngin/okcomputer/badge.svg?branch=master)](https://coveralls.io/r/sportngin/okcomputer)

# OK Computer

Inspired by the ease of installing and setting up [fitter-happier] as a Rails
application's health check, but frustrated by its lack of flexibility, OK
Computer was born. It provides a robust endpoint to perform server health
checks with a set of built-in plugins, as well as a simple interface to add
your own custom checks.

For more insight into why we built this, check out [our blog post introducing
OK Computer][blog].

[blog]:http://pulse.sportngin.com/news_article/show/267646?referrer_id=543230

OkComputer currently supports the following Rails versions:

* 6.0
* 5.2
* 5.1
* 4.2

#### Not using Rails?

If you use [Grape] instead of Rails, check out [okcomputer-grape].

[Grape]:https://github.com/ruby-grape/grape
[okcomputer-grape]:https://github.com/bellycard/okcomputer-grape

## Installation

Add this line to your application's Gemfile:

    gem 'okcomputer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install okcomputer

## Usage

To perform the default checks (application running and ActiveRecord database
connection), do nothing other than adding to your application's Gemfile.

### If Not Using ActiveRecord

We also include a MongoidCheck, but do not register it. If you use Mongoid,
replace the default ActiveRecord check like so:

```ruby
OkComputer::Registry.register "database", OkComputer::MongoidCheck.new
```

If you use another database adapter, see Registering Custom Checks below to
build your own database check and register it with the name "database" to
replace the built-in check, or use `OkComputer::Registry.deregister "database"`
to stop checking your database altogether.

### Requiring Authentication

Optionally require HTTP Basic authentication to view the results of checks in an initializer, like so:

```ruby
# config/initializers/okcomputer.rb
OkComputer.require_authentication("username", "password")
```

To allow access to specific checks without a password, optionally specify the names of the checks:

```ruby
# config/initializers/okcomputer.rb
OkComputer.require_authentication("username", "password", except: %w(default nonsecret))
```

### Changing the OkComputer Route

By default, OkComputer routes are mounted at `/okcomputer`. If you'd like to use an alternate route,
you can configure it with:

```ruby
# config/initializers/okcomputer.rb
OkComputer.mount_at = 'health_checks'    # mounts at /health_checks
```

For more control of adding OkComputer to your routes, set `OkComputer.mount_at
= false` to disable automatic mounting, and you can manually mount the engine
in your `routes.rb`.

```ruby
# config/initializers/okcomputer.rb
OkComputer.mount_at = false

# config/routes.rb, at any priority that suits you
mount OkComputer::Engine, at: "/custom_path"
```

### Logging check results

Log check results by setting `OkComputer.logger`. Note: results will be logged at the `info` level.

```ruby
OkComputer.logger = Rails.logger
```

```sh
[okcomputer] mycheck: PASSED mymessage (0s)
```

### Registering Additional Checks

Register additional checks in an initializer, like so:

```ruby
# config/initializers/okcomputer.rb
OkComputer::Registry.register "resque_down", OkComputer::ResqueDownCheck.new
OkComputer::Registry.register "resque_backed_up", OkComputer::ResqueBackedUpCheck.new("critical", 100)

# This check works on 2.4.0 and above versions of resque-scheduler
OkComputer::Registry.register "resque_scheduler_down", OkComputer::ResqueSchedulerCheck.new
```

### Registering Custom Checks

The simplest way to register a check unique to your application is to subclass
OkComputer::Check and implement your own `#check` method, which sets the
display message with `mark_message`, and calls `mark_failure` if anything is
wrong.

```ruby
# config/initializers/okcomputer.rb
class MyCustomCheck < OkComputer::Check
  def check
    if rand(10).even?
      mark_message "Even is great!"
    else
      mark_failure
      mark_message "We don't like odd numbers"
    end
  end
end

OkComputer::Registry.register "check_for_odds", MyCustomCheck.new
```

### Registering Optional Checks

Register an optional check like so:

```ruby
# ...
OkComputer::Registry.register "some_optional_check", OkComputer::ResqueBackedUpCheck.new("critical", 100)
# ...

OkComputer.make_optional %w(some_optional_check another_optional_check)
```

This check will run and report its status, but will not affect the HTTP status code returned.

### Customizing plain-text output

The plain-text output flows through Rails' internationalization framework.
Adjust the output as necessary by defining `okcomputer.check.passed` and
`okcomputer.check.failed` keys in your setup. The default values are available
[in `okcomputer.en.yml`][i18n].

[i18n]:https://github.com/sportngin/okcomputer/blob/eb0be05cc1527e083edd63cfbb0a071f7892c822/config/locales/okcomputer.en.yml#L1-L5

## Running checks in parallel

By default, OkComputer runs checks in sequence. If you'd like to run them in parallel, you can configure it with:

```ruby
# config/initializers/okcomputer.rb
OkComputer.check_in_parallel = true
```

## Performing Checks

* Perform a simple up check: http://example.com/okcomputer
* Perform all installed checks: http://example.com/okcomputer/all
* Perform a specific installed check: http://example.com/okcomputer/database

Checks are available as plain text (by default) or JSON by appending .json, e.g.:
* http://example.com/okcomputer.json
* http://example.com/okcomputer/all.json

## OkComputer NewRelic Ignore

If NewRelic is installed, OkComputer automatically disables NewRelic monitoring for uptime checks,
as it will start to artificially bring your request time down.

If you'd like to intentionally count OkComputer requests in your NewRelic analytics, set:

```
# config/initializers/okcomputer.rb
OkComputer.analytics_ignore = false
```

## Development

### Setup

```plaintext
$ bundle install
```

### Running the test suite

OkComputer tests are written with [RSpec](http://rspec.info/).

To run the full test suite:

```plaintext
$ rake spec
```

You may also use the environment variable `RAILS_VERSION` with one
of the supported versions of Rails (found at the top of this file) to
bundle and run the tests with a specific version of Rails.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[fitter-happier]:https://rubygems.org/gems/fitter-happier
