# Warden::BasicAuth

[![Build Status](https://travis-ci.org/opf/warden-basic_auth.svg?branch=master)](https://travis-ci.org/opf/warden-basic_auth)
[![Code Climate](https://codeclimate.com/github/opf/warden-basic_auth/badges/gpa.svg)](https://codeclimate.com/github/opf/warden-basic_auth)

Provides a Warden base strategy for basic auth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'warden-basic_auth', '~> 0.1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install warden-basic_auth

## Usage

Subclasses must simply define the method `#authenticate_user`.
The simplest possible implementation is the following example from the specs:

```ruby
class TestBasicAuth < Warden::Strategies::BasicAuth
  def authenticate_user(username, password)
    username == 'admin' && password == 'adminadmin'
  end
end
```

You can register the strategy with Warden like this:

```ruby
Warden::Strategies.add :basic_auth, TestBasicAuth
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/warden-basic_auth/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
