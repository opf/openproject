# CHANGELOG

## [Unreleased]

## [6.4.0] - 2020-09-18
### Security
- CVE-2020-25739: Enforce HTML entities escaping in gon output

## [6.3.2] - 2019-11-18
### Security
- Restrict possibility of vulnerable i18n legacy verision (0.3.6.pre)
  installation

## [6.3.1] - 2019-11-18
### Changed
- ActionView::Base and ActionController::Base should be loaded inside
  ActiveSupport.on_load hook. Thanks to @amatsuda
- Require Ruby >= 2.2.2 (activesupport). Thanks to @nicolasleger
- Update old_rails.rb to reflect GonHelpers -> ControllerHelpers name change.
  Thanks to @etipton

## [6.2.1] - 2018-07-11
### Changed
- Update README: correct spelling mistake. Thanks to @EdwardBetts
- Autoload test classes only in test env. Thanks to @wilddima

### Fixed
- Fix keys cache. Thanks to @ertrzyiks
- fixing tests by running with rabl and rabl-rails separately. Thanks to
  @dsalahutdinov

## [6.2.0] - 2017-10-04
### Added
- Introduce keys cache. Thanks to @vlazar
- Add possibleErrorCallback to watch params. Thanks to @etagwerker

### Changed
- Update readme with PhoenixGon hex link. Thanks to @khusnetdinov
- Fix code highlighting in README. Thanks to @ojab
- Refactoring: use attr_reader

### Removed
- Remove unnecessary json dependency.
- Remove rubysl and rubinius-developer_tools gem.

## [6.1.0] - 2016-07-11
### Deprecated
- env is deprecated and will be removed from Rails 5.0. Thanks to @dlupu

### Fixed
- fix merging routes bug. Thanks to @strikyflo
- Show what method was used in public methods error.

### Changed
- Use 'need_tag' as option name to prevent calling 'tag' method. Thanks to
  @june29
- Update README; comment out gon.clear from sample code. Thanks to
  @speee-nakajima
- Update README; Replace the include_gon method with render_data method.
- Refactoring: use attr_accessor method.
- Refactoring: use attr_reader method.

## [6.0.1] - 2015-07-22
### Changed
- Free dependencies

## [6.0.0] - 2015-07-22
### Added
- nonce option. Thanks to @joeljackson

### Changed
- Refactoring
- Included rails url_helpers into jbuilder. Thanks to @razum2um

## [5.2.3] - 2014-11-03
### Added
- Coffescript implementation of watch.js. Thanks to @willcosgrove
- unwatchAll function in watch.js. Thanks to @willcosgrove

## [5.2.2] - 2014-10-31
### Added
- support for controller helper methods in jbuilder

## [5.2.1] - 2014-10-28
### Added
- merge variable feature (for merge hash-like variables instead of overriding
  them). Thanks to @jalkoby

### Fixed
- fix for jbuilder module. Thanks to @jankovy

## [5.2.0] - 2014-08-26
### Added
- namespace_check option. Thanks to @tommyh
- AMD compatible version of including gon. Thanks to @vijoc

### Changed
- Only inject gon into ActionController::Base-like object in spec_helper. Thanks
  to @kevinoconnor7

### Fixed
- fix issue where include_gon would raise exception if the controller did not
  assign any gon variables. Thanks to @asalme

## [5.1.2] - 2014-07-22
### Changed
- Clarifying helpers, dump gon#watch content to safe json before render. Thanks
  to @Strech

## [5.1.1] - 2014-07-17
### Added
- global_root option. Thanks to @rafaelliu
- MultiJson support. Thanks to @Strech

## [5.1.0] - 2014-06-29
### Fixed
- Many fixes. Thanks to @Silex, @kilefritz, @irobayna, @kyrylo, @randoum,
  @jackquack, @tuvistavie, @Strech for awesome commits and help!

## [5.0.4] - 2014-02-13
### Fixed
- Fix check for get and assign variables for Gon.global

## [5.0.3] - 2014-02-12
### Removed
- Revert changes in gemspec

## [5.0.2] - 2014-02-12
### Fixed
- Fix issue when there is no gon object for current thread and rendering
  include_gon (#108 part) (wasn't fixed) (@gregmolnar)

## [5.0.1] - 2013-12-30
### Fixed
- Fix issue when there is no gon object for current thread and rendering
  include_gon (#108 part)

## [5.0.0] - 2013-12-26
### Changed
- Gon is threadsafe now! (@razum2um)
- Camelcasing with depth (@MaxSchmeling)
- Optional CDATA and style refactoring (@torbjon)
- jBuilder supports not only String and Hash types of locals (@steakchaser)
- Using ActionDispatch::Request#uuid instead of ActionDispatch::Request#id
  (@sharshenov)

## [4.1.1] - 2013-06-04
### Fixed
- Fixed critical XSS vulnerability https://github.com/gazay/gon/issues/84
  (@vadimr & @Hebo)

## [4.1.0] - 2013-04-14
### Added
- rabl-rails support (@jtherrell)

### Changed
- Refactored script tag generation (@toothrot)
- Stop support for MRI 1.8.7
- Accepting locals in jbuilder templates

## [4.0.3] - 2013-04-14
!!!IMPORTANT!!! Last version with compatibility for MRI 1.8.7

### Added
- new method `Gon#push` for assign variables through Hash-like objects (@topdev)
### Changed
- Fixes for 1.8.7 compatibility.

## [4.0.2] - 2012-12-17
### Fixed
- Fixed gon.watch in JS without callback and options

## [4.0.1] - 2012-10-25
### Added
- option :locals to gon.rabl functionality

### Changed
- Gon#set_variable and Gon#get_variable moved to public scope

### Removed
- BlankSlate requirement (@phoet)

## [4.0.0] - 2012-07-23
### Added
- gon.watch functionality (thanks to @brainopia and @kossnocorp)
- Compatibility with jbuilder paths for partial! method

### Changed
- Little bit refactoring - Gon now is a class

### Fixed
- Fixed some bugs

## [3.0.5] - 2012-06-22
### Added
- type text/javascript option (@torbjon)

### Changed
- A litlle bit refactoring
- Made compatible with active support json encoding for escaping script tags

### Fixed
- bug for init option
- clear if init true (@torbjon)

## [3.0.4] - 2012-06-02
### Fixed
- Fix bug with gon clear with global variables, bump version

## [3.0.3] - 2012-05-22
### Added
- init option (@torbjon)

### Changed
- Include ActionView::Helpers into Gon::JBuilder

## [3.0.2] - 2012-04-28
### Added
- need_tag option (@afa)

## [3.0.0] - 2012-04-17
### Added
- Added Gon.global for using gon everywhere

### Changed
- Almost all code refactored
- Included ActionView::Helpers into Rabl::Engine

## [2.3.0] - 2012-04-09
### Changed
- Don't really remember what was before this version

[Unreleased]: https://github.com/gazay/gon/compare/v6.3.2...master
[6.3.2]: https://github.com/gazay/gon/compare/v6.3.1...v6.3.2
[6.3.1]: https://github.com/gazay/gon/compare/v6.2.1...v6.3.1
[6.2.1]: https://github.com/gazay/gon/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/gazay/gon/compare/v6.1.0...v6.2.0
[6.1.0]: https://github.com/gazay/gon/compare/v6.0.1...v6.1.0
[6.0.1]: https://github.com/gazay/gon/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/gazay/gon/compare/v5.2.3...v6.0.0
[5.2.3]: https://github.com/gazay/gon/compare/v5.2.2...v5.2.3
[5.2.2]: https://github.com/gazay/gon/compare/v5.2.1...v5.2.2
[5.2.1]: https://github.com/gazay/gon/compare/v5.2.0...v5.2.1
[5.2.0]: https://github.com/gazay/gon/compare/v5.1.2...v5.2.0
[5.1.2]: https://github.com/gazay/gon/compare/v5.1.1...v5.1.2
[5.1.1]: https://github.com/gazay/gon/compare/v5.1.0...v5.1.1
[5.1.0]: https://github.com/gazay/gon/compare/v5.0.4...v5.1.0
[5.0.4]: https://github.com/gazay/gon/compare/v5.0.3...v5.0.4
[5.0.3]: https://github.com/gazay/gon/compare/v5.0.2...v5.0.3
[5.0.2]: https://github.com/gazay/gon/compare/v5.0.1...v5.0.2
[5.0.1]: https://github.com/gazay/gon/compare/v5.0.0...v5.0.1
[5.0.0]: https://github.com/gazay/gon/compare/v4.1.1...v5.0.0
[4.1.1]: https://github.com/gazay/gon/compare/v4.1.0...v4.1.1
[4.1.0]: https://github.com/gazay/gon/compare/v4.0.3...v4.1.0
[4.0.3]: https://github.com/gazay/gon/compare/v4.0.2...v4.0.3
[4.0.2]: https://github.com/gazay/gon/compare/v4.0.1...v4.0.2
[4.0.1]: https://github.com/gazay/gon/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/gazay/gon/compare/v3.0.5...v4.0.0
[3.0.5]: https://github.com/gazay/gon/compare/v3.0.4...v3.0.5
[3.0.4]: https://github.com/gazay/gon/compare/v3.0.3...v3.0.4
[3.0.3]: https://github.com/gazay/gon/compare/v3.0.2...v3.0.3
[3.0.2]: https://github.com/gazay/gon/compare/v3.0.0...v3.0.2
[3.0.0]: https://github.com/gazay/gon/compare/v2.3.0...v3.0.0
[2.3.0]: https://github.com/gazay/gon/releases/tag/v2.3.0
