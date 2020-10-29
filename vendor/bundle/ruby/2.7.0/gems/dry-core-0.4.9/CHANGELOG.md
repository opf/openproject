# v0.4.9

### Added

- `Undefined.coalesce` takes a variable number of arguments and returns the first non-`Undefined` value (flash-gordon)
  ```ruby
  Undefined.coalesce(Undefined, Undefined, :foo) # => :foo
  ```

### Fixed

- `Undefined.{dup,clone}` returns `Undefined` back, `Undefined` is a singleton (flash-gordon)

[Compare v0.4.8...v0.4.9](https://github.com/dry-rb/dry-core/compare/v0.4.8...v0.4.9)

# v0.4.8 2019-06-23

### Added

- `Undefined.map` for mapping non-undefined values (flash-gordon):

```ruby
something = 1
Undefined.map(something) { |v| v + 1 } # => 2
something = Undefined
Undefined.map(something) { |v| v + 1 } # => Undefined
```

[Compare v0.4.7...v0.4.8](https://github.com/dry-rb/dry-core/compare/v0.4.7...v0.4.8)

# v0.4.7 2018-06-25

### Fixed

- Fix default logger for deprecations, it now uses `$stderr` by default, as it should (flash-gordon)

[Compare v0.4.6...v0.4.7](https://github.com/dry-rb/dry-core/compare/v0.4.6...v0.4.7)

# v0.4.6 2018-05-15

### Changed

- Trigger constant autoloading in the class builder (radar)

[Compare v0.4.5...v0.4.6](https://github.com/dry-rb/dry-core/compare/v0.4.5...v0.4.6)

# v0.4.5 2018-03-14

### Added

- `Dry::Core::Memoizable`, which provides a `memoize` macro for memoizing results of instance methods (timriley)

[Compare v0.4.4...v0.4.5](https://github.com/dry-rb/dry-core/compare/v0.4.4...v0.4.5)

# v0.4.4 2018-02-10

### Added

- `deprecate_constant` overrides `Module#deprecate_constant` and issues a labeled message on accessing a deprecated constant (flash-gordon)
- `Undefined.default` which accepts two arguments and returns the first if it's not `Undefined`; otherwise, returns the second one or yields a block (flash-gordon)

[Compare v0.4.3...v0.4.4](https://github.com/dry-rb/dry-core/compare/v0.4.3...v0.4.4)

# v0.4.3 2018-02-03

### Added

- `Dry::Core::DescendantsTracker` which is a maintained version of the [`descendants_tracker`](https://github.com/dkubb/descendants_tracker) gem (flash-gordon)

[Compare v0.4.2...v0.4.3](https://github.com/dry-rb/dry-core/compare/v0.4.2...0.4.3)

# v0.4.2 2017-12-16

### Fixed

- Class attributes now support private setters/getters (flash-gordon)

[Compare v0.4.1...v0.4.2](https://github.com/dry-rb/dry-core/compare/v0.4.1...v0.4.2)

# v0.4.1 2017-11-04

### Changed

- Improved error message on invalid attribute value (GustavoCaso)

[Compare v0.4.0...v0.4.1](https://github.com/dry-rb/dry-core/compare/v0.4.0...v0.4.1)

# v0.4.0 2017-11-02

### Added

- Added the `:type` option to class attributes, you can now restrict attribute values with a type. You can either use plain ruby types (`Integer`, `String`, etc) or `dry-types` (GustavoCaso)

  ```ruby
    class Foo
      extend Dry::Core::ClassAttributes

      defines :ruby_attr, type: Integer
      defines :dry_attr, type: Dry::Types['strict.int']
    end
  ```

[Compare v0.3.4...v0.4.0](https://github.com/dry-rb/dry-core/compare/v0.3.4...v0.4.0)

# v0.3.4 2017-09-29

### Fixed

- `Deprecations` output is set to `$stderr` by default now (solnic)

[Compare v0.3.3...v0.3.4](https://github.com/dry-rb/dry-core/compare/v0.3.3...v0.3.4)

# v0.3.3 2017-08-31

### Fixed

- The Deprecations module now shows the right caller line (flash-gordon)

[Compare v0.3.2...v0.3.3](https://github.com/dry-rb/dry-core/compare/v0.3.2...v0.3.3)

# v0.3.2 2017-08-31

### Added

- Accept an existing logger object in `Dry::Core::Deprecations.set_logger!` (flash-gordon)

[Compare v0.3.1...v0.3.2](https://github.com/dry-rb/dry-core/compare/v0.3.1...v0.3.2)

# v0.3.1 2017-05-27

### Added

- Support for building classes within an existing namespace (flash-gordon)

[Compare v0.3.0...v0.3.1](https://github.com/dry-rb/dry-core/compare/v0.3.0...v0.3.1)

# v0.3.0 2017-05-05

### Changed

- Class attributes are initialized _before_ running the `inherited` hook. It's slightly more convenient behavior and it's very unlikely anyone will be affected by this, but technically this is a breaking change (flash-gordon)

[Compare v0.2.4...v0.3.0](https://github.com/dry-rb/dry-core/compare/v0.2.4...v0.3.0)

# v0.2.4 2017-01-26

### Fixed

- Do not require deprecated method to be defined (flash-gordon)

[Compare v0.2.3...v0.2.4](https://github.com/dry-rb/dry-core/compare/v0.2.3...v0.2.4)

# v0.2.3 2016-12-30

### Fixed

- Fix warnings on using uninitialized class attributes (flash-gordon)

[Compare v0.2.2...v0.2.3](https://github.com/dry-rb/dry-core/compare/v0.2.2...v0.2.3)

# v0.2.2 2016-12-30

### Added

- `ClassAttributes` which provides `defines` method for defining get-or-set methods (flash-gordon)

[Compare v0.2.1...v0.2.2](https://github.com/dry-rb/dry-core/compare/v0.2.1...v0.2.2)

# v0.2.1 2016-11-18

### Added

- `Constants` are now available in nested scopes (flash-gordon)

[Compare v0.2.0...v0.2.1](https://github.com/dry-rb/dry-core/compare/v0.2.0...v0.2.1)

# v0.2.0 2016-11-01

[Compare v0.1.0...v0.2.0](https://github.com/dry-rb/dry-core/compare/v0.1.0...v0.2.0)

# v0.1.0 2016-09-17

Initial release
