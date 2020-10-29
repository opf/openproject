[gem]: https://rubygems.org/gems/dry-equalizer
[ci]: https://github.com/dry-rb/dry-equalizer/actions?query=workflow%3Aci
[codeclimate]: https://codeclimate.com/github/dry-rb/dry-equalizer
[chat]: https://dry-rb.zulipchat.com

# dry-equalizer [![Join the chat at https://dry-rb.zulipchat.com](https://img.shields.io/badge/dry--rb-join%20chat-%23346b7a.svg)][chat]

Module to define equality, equivalence and inspection methods

[![Gem Version](http://img.shields.io/gem/v/dry-equalizer.svg)][gem]
[![Build Status](https://github.com/dry-rb/dry-equalizer/workflows/ci/badge.svg)][ci]
[![Maintainability](https://api.codeclimate.com/v1/badges/5a9a139af1d4a80a28c4/maintainability)][codeclimate]
[![Test Coverage](https://api.codeclimate.com/v1/badges/5a9a139af1d4a80a28c4/test_coverage)][codeclimate]

## Examples

```ruby
class GeoLocation
  include Dry::Equalizer(:latitude, :longitude)

  attr_reader :latitude, :longitude

  def initialize(latitude, longitude)
    @latitude, @longitude = latitude, longitude
  end
end

point_a = GeoLocation.new(1, 2)
point_b = GeoLocation.new(1, 2)
point_c = GeoLocation.new(2, 2)

point_a.inspect    # => "#<GeoLocation latitude=1 longitude=2>"

point_a == point_b           # => true
point_a.hash == point_b.hash # => true
point_a.eql?(point_b)        # => true
point_a.equal?(point_b)      # => false

point_a == point_c           # => false
point_a.hash == point_c.hash # => false
point_a.eql?(point_c)        # => false
point_a.equal?(point_c)      # => false
```

## Supported Ruby Versions

This library aims to support and is [tested against][travis] the following Ruby
implementations:

- MRI 2.4+
- JRuby 9.x

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions or
implementations, however support will only be provided for the implementations
listed above.

If you would like this library to support another Ruby version or
implementation, you may volunteer to be a maintainer. Being a maintainer
entails making sure all tests run and pass on that implementation. When
something breaks on your implementation, you will be responsible for providing
patches in a timely fashion. If critical issues for a particular implementation
exist at the time of a major release, support for that Ruby version may be
dropped.

## Credits

This is a fork of the original [equalizer](https://github.com/dkubb/equalizer).

- Dan Kubb ([dkubb](https://github.com/dkubb))
- Piotr Solnica ([solnic](https://github.com/solnic))
- Markus Schirp ([mbj](https://github.com/mbj))
- Erik Michaels-Ober ([sferik](https://github.com/sferik))

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Copyright

Copyright &copy; 2009-2013 Dan Kubb. See LICENSE for details.
