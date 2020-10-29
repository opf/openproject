## 1.0.7 2020-08-13


### Added

- A new `uri?` predicate that you can use to verify `URI` strings, ie `uri?("https", "https://dry-rb.org")` (@nerburish)
- New predicates: `uuid_v1?`, `uuid_v2?`, `uuid_v3?` and `uuid_v5?` (via #75) (@jamesbrauman)


[Compare v1.0.6...v1.0.7](https://github.com/dry-rb/dry-logic/compare/v1.0.6...v1.0.7)

## 1.0.6 2020-02-10


### Fixed

- Made the regexp used by `uuid_v4?` more secure (@kml)


[Compare v1.0.5...v1.0.6](https://github.com/dry-rb/dry-logic/compare/v1.0.5...v1.0.6)

## 1.0.5 2019-11-07


### Fixed

- Make `format?` tolerant to `nil` values. It already worked like that before, but starting Ruby 2.7 it would produce warnings. Now it won't. Don't rely on this behavior, it's only added to make tests pass in dry-schema. Use explicit type checks instead (@flash-gordon)


[Compare v1.0.4...v1.0.5](https://github.com/dry-rb/dry-logic/compare/v1.0.4...v1.0.5)

## 1.0.4 2019-11-06


### Fixed

- Fix keyword warnings (@flash-gordon)


[Compare v1.0.3...v1.0.4](https://github.com/dry-rb/dry-logic/compare/v1.0.3...v1.0.4)

## 1.0.3 2019-08-01


### Added

- `bytesize?` predicate (@bmalinconico)
- `min_bytesize?` predicate (@bmalinconico)
- `max_bytesize? predicate (@bmalinconico)

### Changed

- Min ruby version was set to `>= 2.4.0` (@flash-gordon)

[Compare v1.0.2...v1.0.3](https://github.com/dry-rb/dry-logic/compare/v1.0.2...v1.0.3)

## 1.0.2 2019-06-14

Re-pushed 1.0.1 after dry-schema 1.2.0 release.


[Compare v1.0.1...v1.0.2](https://github.com/dry-rb/dry-logic/compare/v1.0.1...v1.0.2)

## 1.0.1 2019-06-04

This release was removed from rubygems because it broke dry-schema.

### Added

- `uuid_v4?` predicate (radar)
- `respond_to?` predicate (waiting-for-dev)


[Compare v1.0.0...v1.0.1](https://github.com/dry-rb/dry-logic/compare/v1.0.0...v1.0.1)

## 1.0.0 2019-04-23


### Changed

- Version bump to `1.0.0` (flash-gordon)

[Compare v0.6.1...v1.0.0](https://github.com/dry-rb/dry-logic/compare/v0.6.1...v1.0.0)

## 0.6.1 2019-04-18


### Fixed

- Fix a regression in dry-validation 0.x for argument-less predicates (flash-gordon)


[Compare v0.6.0...v0.6.1](https://github.com/dry-rb/dry-logic/compare/v0.6.0...v0.6.1)

## 0.6.0 2019-04-04


### Added

- Generating hints can be disabled by building `Operations::And` with `hints: false` option set (solnic)

### Changed

- `Rule` construction has been optimized so that currying and application is multiple-times faster (flash-gordon)

[Compare v0.5.0...v0.6.0](https://github.com/dry-rb/dry-logic/compare/v0.5.0...v0.6.0)

## 0.5.0 2019-01-29


### Added

- `:nil?` predicate (`none?` is now an alias) (solnic)

### Fixed

- `Operation::Key#ast` will now return a correct AST with non-Undefined inputs (solnic)


[Compare v0.4.2...v0.5.0](https://github.com/dry-rb/dry-logic/compare/v0.4.2...v0.5.0)

## 0.4.2 2017-09-15


### Added

- New `:case?` predicate matches a value against the given object with `#===` (flash-gordon)
- New `:is?` predicate checks objects identity (using `#equal?`) (flash-gordon)

### Fixed

- A bug with using custom predicates within a standalone module in `dry-validation` (flash-gordon)


[Compare v0.4.1...v0.4.2](https://github.com/dry-rb/dry-logic/compare/v0.4.1...v0.4.2)

## 0.4.1 2017-01-23


### Fixed

- Warnings on MRI 2.4.0 are gone (jtippett)

### Changed

- Predicates simply reuse other predicate methods instead of referring to them via `#[]` (georgemillo)

[Compare v0.4.0...v0.4.1](https://github.com/dry-rb/dry-logic/compare/v0.4.0...v0.4.1)

## 0.4.0 2016-09-21

This is a partial rewrite focused on internal clean up and major performance improvements. This is also the beginning of the work to make this library first-class rather than "just" a rule backend for dry-validation and dry-types.

### Added

- `Rule#[]` which applies a rule and always returns `true` or `false` (solnic)
- `Rule#bind` which returns a rule with its predicate bound to a given object (solnic)
- `Rule#eval_args` which evaluates unbound-methods-args in the context of a given object (solnic)
- `Logic.Rule` builder function (solnic)
- Nice `#inspect` on rules and operation objects (solnic)

### Changed

- [BRAEKING] New result API (solnic)
- [BREAKING] `Predicate` is now `Rule::Predicate` (solnic)
- [BREAKING] `Rule::Conjunction` is now `Operation::And` (solnic)
- [BREAKING] `Rule::Disjunction` is now `Operation::Or` (solnic)
- [BREAKING] `Rule::ExlusiveDisjunction` is now `Operation::Xor` (solnic)
- [BREAKING] `Rule::Implication` is now `Operation::Implication` (solnic)
- [BREAKING] `Rule::Set` is now `Operation::Set` (solnic)
- [BREAKING] `Rule::Each` is now `Operation::Each` (solnic)
- [BREAKING] `Rule.new` accepts a predicate function as its first arg now (solnic)
- [BREAKING] `Rule#name` is now `Rule#id` (solnic)
- `Rule#parameters` is public now (solnic)

[Compare v0.3.0...v0.4.0](https://github.com/dry-rb/dry-logic/compare/v0.3.0...v0.4.0)

## 0.3.0 2016-07-01


### Added

- `:type?` predicate imported from dry-types (solnic)
- `Rule#curry` interface (solnic)

### Changed

- Predicates AST now includes information about args (names & possible values) (fran-worley + solnic)
- Predicates raise errors when they are called with invalid arity (fran-worley + solnic)
- Rules no longer evaluate input twice when building result objects (solnic)

[Compare v0.2.3...v0.3.0](https://github.com/dry-rb/dry-logic/compare/v0.2.3...v0.3.0)

## 0.2.3 2016-05-11


### Added

- `not_eql?`, `includes?`, `excludes?` predicates (fran-worley)

### Changed

- Renamed `inclusion?` to `included_in?` and deprecated `inclusion?` (fran-worley)
- Renamed `exclusion?` to `excluded_from?` and deprecated `exclusion?` (fran-worley)

[Compare v0.2.2...v0.2.3](https://github.com/dry-rb/dry-logic/compare/v0.2.2...v0.2.3)

## 0.2.2 2016-03-30


### Added

- `number?`, `odd?`, `even?` predicates (fran-worley)


[Compare v0.2.1...v0.2.2](https://github.com/dry-rb/dry-logic/compare/v0.2.1...v0.2.2)

## 0.2.1 2016-03-20


### Fixed

- Result AST for `Rule::Each` correctly maps elements with eql inputs (solnic)


[Compare v0.2.0...v0.2.1](https://github.com/dry-rb/dry-logic/compare/v0.2.0...v0.2.1)

## 0.2.0 2016-03-11


### Changed

- Entire AST has been redefined (solnic)

[Compare v0.1.4...v0.2.0](https://github.com/dry-rb/dry-logic/compare/v0.1.4...v0.2.0)

## 0.1.4 2016-01-27


### Added

- Support for hash-names in `Check` and `Result` which can properly resolve input
  from nested results (solnic)


[Compare v0.1.3...v0.1.4](https://github.com/dry-rb/dry-logic/compare/v0.1.3...v0.1.4)

## 0.1.3 2016-01-27


### Added

- Support for resolving input from `Rule::Result` (solnic)

### Changed

- `Check` and `Result` carry original input(s) (solnic)

[Compare v0.1.2...v0.1.3](https://github.com/dry-rb/dry-logic/compare/v0.1.2...v0.1.3)

## 0.1.2 2016-01-19


### Fixed

- `xor` returns wrapped results when used against another result-rule (solnic)


[Compare v0.1.1...v0.1.2](https://github.com/dry-rb/dry-logic/compare/v0.1.1...v0.1.2)

## 0.1.1 2016-01-18


### Added

- `Rule::Attr` which can be applied to a data object with attr readers (SunnyMagadan)
- `Rule::Result` which can be applied to a result object (solnic)
- `true?` and `false?` predicates (solnic)


[Compare v0.1.0...v0.1.1](https://github.com/dry-rb/dry-logic/compare/v0.1.0...v0.1.1)

## 0.1.0 2016-01-11

Code extracted from dry-validation 0.4.1
