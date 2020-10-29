# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2020-07-12
### Added
- IV arguments can be either `String`s or `Integer`s. Previously, they could
  only be `Integer`s. This is a backwards-compatible addition as long as you
  aren't doing something freaky with IVs, like using negative numbers (they are
  supposed to be unsigned).

## [1.0.1] - 2015-04-24
### Fixed
- Didn't work unless you had `require 'openssl'` somewhere first. The gem now
  `require`s its own dependencies, surprising no one.

## [1.0.0] - 2015-04-24
### Added
- Everything (Initial release)
