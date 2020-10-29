[gitter]: https://gitter.im/dry-rb/chat
[gem]: https://rubygems.org/gems/dry-core
[travis]: https://travis-ci.org/dry-rb/dry-core
[code_climate]: https://codeclimate.com/github/dry-rb/dry-core
[inch]: http://inch-ci.org/github/dry-rb/dry-core
[chat]: https://dry-rb.zulipchat.com

# dry-core [![Join the chat at https://dry-rb.zulipchat.com](https://img.shields.io/badge/dry--rb-join%20chat-%23346b7a.svg)][chat]

[![Gem Version](https://img.shields.io/gem/v/dry-core.svg)][gem]
[![Build Status](https://img.shields.io/travis/dry-rb/dry-core.svg)][travis]
[![Code Climate](https://api.codeclimate.com/v1/badges/eebb0e969814744231e4/maintainability)][code_climate]
[![Test Coverage](https://api.codeclimate.com/v1/badges/eebb0e969814744231e4/test_coverage)][code_climate]
[![API Documentation Coverage](http://inch-ci.org/github/dry-rb/dry-core.svg)][inch]
![No monkey-patches](https://img.shields.io/badge/monkey--patches-0-brightgreen.svg)

A collection of small modules used in the dry-rb ecosystem.

## Links

* [User docs](https://dry-rb.org/gems/dry-core)
* [API docs](http://rubydoc.info/gems/dry-core)

## Supported Ruby versions

This library officially supports following Ruby versions:

* MRI >= `2.4`
* jruby >= `9.2`

It **should** work on MRI `2.3.x` too, but there's no official support for this version.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-core'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-core

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dry-rb/dry-core.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
