[gem]: https://img.shields.io/gem/v/dry-inflector.svg
[travis]: https://travis-ci.org/dry-rb/dry-inflector
[codeclimate]: https://codeclimate.com/github/dry-rb/dry-inflector
[chat]: https://dry-rb.zulipchat.com
[inchpages]: http://inch-ci.org/github/dry-rb/dry-inflector

# dry-inflector [![Join the chat at https://dry-rb.zulipchat.com](https://img.shields.io/badge/dry--rb-join%20chat-%23346b7a.svg)][chat]

[![Gem Version](https://badge.fury.io/rb/dry-inflector.svg)][gem]
[![Build Status](https://travis-ci.org/dry-rb/dry-inflector.svg?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/dry-rb/dry-inflector/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/dry-rb/dry-inflector/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/dry-rb/dry-inflector.svg?branch=master)][inchpages]

dry-inflector is an inflector gem for Ruby.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'dry-inflector'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install dry-inflector
```

## Usage

### Basic usage

```ruby
require "dry/inflector"

inflector = Dry::Inflector.new

inflector.pluralize("book")    # => "books"
inflector.singularize("books") # => "book"

inflector.camelize("dry/inflector") # => "Dry::Inflector"
inflector.classify("books")         # => "Book"
inflector.tableize("Book")          # => "books"

inflector.dasherize("dry_inflector")  # => "dry-inflector"
inflector.underscore("dry-inflector") # => "dry_inflector"

inflector.demodulize("Dry::Inflector") # => "Inflector"

inflector.humanize("dry_inflector")    # => "Dry inflector"
inflector.humanize("author_id")        # => "Author"

inflector.ordinalize(1)  # => "1st"
inflector.ordinalize(2)  # => "2nd"
inflector.ordinalize(3)  # => "3rd"
inflector.ordinalize(10) # => "10th"
inflector.ordinalize(23) # => "23rd"
```

### Custom inflection rules

```ruby
require "dry/inflector"

inflector = Dry::Inflector.new do |inflections|
  inflections.plural      "virus",   "viruses" # specify a rule for #pluralize
  inflections.singular    "thieves", "thief"   # specify a rule for #singularize
  inflections.uncountable "dry-inflector"      # add an exception for an uncountable word
end

inflector.pluralize("virus")     # => "viruses"
inflector.singularize("thieves") # => "thief"

inflector.pluralize("dry-inflector") # => "dry-inflector"
```

## Credits

This gem is the cumulative effort of the Ruby community.
It started with the extlib inflecto originated from [active_support](https://github.com/rails/rails), then dm-core inflector originated from [extlib](https://github.com/datamapper/extlib).
Later, [`inflecto`](https://github.com/mbj/inflecto) was extracted from [dm-core](https://github.com/datamapper/dm-core) as a standalone inflector.
Now, we resurrect `inflecto` and merged [`flexus`](https://github.com/Ptico/flexus), with some inflection rules from [`hanami-utils`](https://github.com/hanami/utils).

This is `dry-inflector`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dry-rb/dry-inflector.

## Copyright

Copyright © The Dry, Rails, Merb, Datamapper, Inflecto, Flexus, and Hanami teams - Released under the MIT License
