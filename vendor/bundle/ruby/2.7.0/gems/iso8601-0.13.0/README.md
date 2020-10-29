# ISO8601

**[New maintainer wanted](https://github.com/arnau/ISO8601/issues/50)**

Version 0.9.0 is **not compatible** with previous versions.  Atoms and Durations
changed their interface when treating base dates so it is only applied when
computing the Atom length (e.g. `#to_seconds`).  As a consequence, it is no
longer possible to do operations like `DateTime + Duration`.

Version 1.0.0 will lock public interfaces.

Check the [changelog](https://github.com/arnau/ISO8601/blob/master/CHANGELOG.md) if you are upgrading from an older version.

ISO8601 is a simple implementation of the ISO 8601 (Data elements and
interchange formats — Information interchange — Representation of dates and
times) standard.

## Build status

[![Build Status](https://secure.travis-ci.org/arnau/ISO8601.png?branch=master)](http://travis-ci.org/arnau/ISO8601/)
[![Gem Version](https://badge.fury.io/rb/iso8601.svg)](http://badge.fury.io/rb/iso8601)

## Supported versions

* MRI 2.5, 2.6, 2.7

## Documentation

Check the [rubydoc documentation](http://www.rubydoc.info/gems/iso8601). Or
take a look to the implementation notes:

* [Date, Time, DateTime](docs/date-time.md)
* [Duration](docs/duration.md)
* [Time interval](docs/time-interval.md)


## Testing

Install a Ruby version. E.g. you can install Ruby 2.7 with:

```
$ nix-shell
```

Then

```
$ bundle install
$ bundle exec rake
```

## Contributing

[Contributors](https://github.com/arnau/ISO8601/graphs/contributors)

Please see [CONTRIBUTING.md](./CONTRIBUTING.md)


## License

Arnau Siches under the [MIT License](https://github.com/arnau/ISO8601/blob/master/LICENSE)
