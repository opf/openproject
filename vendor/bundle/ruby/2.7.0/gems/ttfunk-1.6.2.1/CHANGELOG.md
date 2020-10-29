# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).


## [Unreleased]

## [1.6.2.1]

### Fixed

* 1.6.2 gem conains local debuging code. This is the same commit but without
  local changes.

  Alexander Mankuta

## [1.6.2]

### Fixed

* Reverted to pre 1.6 maxp table serialization.

  Cameron Dutro

## [1.6.1]

### Fixed

* Fixed maxp table encoding

  Cameron Dutro

## [1.6.0]

### Added

* OpenType fonts support

  * Added support for CFF-flavored fonts (also known as CID-keyed or OpenType fonts)
  * Added support for the VORG and DSIG tables
  * Improved charset encoding support
  * Improved font metrics calculations in the head, maxp, hhea, hmtx, and os/2 tables
  * Subsetted fonts verified with Font-Validator, fontlint, and Mac OS's Font Book

  Cameron Dutro

* Ruby 2.6 support

  Alexander Mankuta

* JRuby 9.2 support

  Alexander Mankuta

### Removed

* Dropped Ruby 2.1 & 2.2 support

  Alexander Mankuta

* Removed JRuby 9.1 support

  Alexander Mankuta

### Fixed

* Sort name table entries when generating subset font

  Matjaz Gregoric

* Map the 0xFFFF char code to glyph 0 in cmap format 4

  Matjaz Gregoric

* Order tables by tag when generating font subset

  Matjaz Gregoric

* Fix typo in TTFunk::Subset::Unicode#includes?

  Matjaz Gregoric

* Fixe calculation of search_range for font subsets

  Matjaz Gregoric

* Fixed instance variable @offset and @length not initialized

  Katsuya HIDAKA

* Code style fixes

  Katsuya HIDAKA, Matjaz Gregoric, Alexander Mankuta

## [1.5.1]

### Fixed

* loca table corruption during subsetting. The loca table serialization code
  didn't properly detect suitable table format.

* Fixed checksum calculation for empty tables.

## [1.5.0] - 2017-02-13

### Added

* Support for reading TTF fonts from TTC files

### Changed

* Subset font naming is consistent now and depends on content


## [1.4.0] - 2014-09-21

### Added

* sbix table support


## [1.3.0] - 2014-09-10

### Removed

* Post table version 2.5


## [1.2.2] - 2014-08-29

### Fixed

* Ignore unsupported cmap table versions


## [1.2.1] - 2014-08-28

### Fixed

* Added missing Pathname require


## [1.2.0] - 2014-06-23

### Added

* Rubocop checks
* Ability to parse IO objects

### Changed

* Improved preferred family name selection


## [1.1.1] - 2014-02-24

### Changed

* Clarified licensing

### Removed

* comicsans.ttf


## [1.1.0] - 2014-01-21

### Added

* Improved Unicode astral planes support
* Support for cmap table formats 6, 10, 12
* RSpec-based specs

### Fixed

* Subsetting in JRuby


## [1.0.3] - 2011-10-11

### Added

* Authorship information


## 1.0.2 - 2011-08-08

### Fixed

* Ruby 1.9.2 segmentation fault on Enumerable#zip(range)


## 1.0.0 - 2011-04-02 [YANKED]

Initial release as a standalone gem



[Unreleased]: https://github.com/prawnpdf/ttfunk/compare/1.6.2...HEAD
[1.6.2]: https://github.com/prawnpdf/ttfunk/compare/1.6.1...1.6.2
[1.6.1]: https://github.com/prawnpdf/ttfunk/compare/1.6.0...1.6.1
[1.6.0]: https://github.com/prawnpdf/ttfunk/compare/1.5.1...1.6.0
[1.5.1]: https://github.com/prawnpdf/ttfunk/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/prawnpdf/ttfunk/compare/1.4.0...1.5.0
[1.4.0]: https://github.com/prawnpdf/ttfunk/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/prawnpdf/ttfunk/compare/1.2.2...1.3.0
[1.2.2]: https://github.com/prawnpdf/ttfunk/compare/1.2.1...1.2.2
[1.2.1]: https://github.com/prawnpdf/ttfunk/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/prawnpdf/ttfunk/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/prawnpdf/ttfunk/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/prawnpdf/ttfunk/compare/1.0.3...1.1.0
[1.0.3]: https://github.com/prawnpdf/ttfunk/compare/1.0.2...1.0.3
