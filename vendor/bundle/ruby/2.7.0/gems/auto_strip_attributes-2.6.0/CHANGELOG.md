## [Master]

## [2.6]

  - Support for `array` attributes (thnks to [@sharshenov](https://github.com/holli/auto_strip_attributes/pull/29))

## [2.5]

  - Support for callback options (e.g. if: -> ...) (thnks to [@watsonjon#28](https://github.com/holli/auto_strip_attributes/pull/28))

## [2.4]

  - Using `ActiveSupport.on_load(:active_record)` instead of direct `extend`. ([#26](https://github.com/holli/auto_strip_attributes/commit/02431f07fcd880baaa352fc3e5a47d07c6d3935d))
  - Possibility to pass options to custom filters. ([@nasa42#27](https://github.com/holli/auto_strip_attributes/pull/27))
  - Rewritten to use keyword arguments instead of hash, and other Ruby 2 stuff 

## [2.3] - 2018-02-06

  - Replacing all utf8 characters in squish (thnks to [@nasa42](https://github.com/holli/auto_strip_attributes/pull/24))

## [2.2] - 2016-07-28

  - Added 'virtual'-option (thnks to [@nasa42](https://github.com/holli/auto_strip_attributes/pull/23))

## [2.1] - 2016-07-28

  - Drop support for ruby 1.9.3

## [2.0.6] - 2014-07-29

  - Some file permission issues

## [2.0.5] - 2014-06-03

  - Added :convert_non_breaking_spaces filter (https://github.com/holli/auto_strip_attributes/pull/12)

## [2.0] - 2011-11-23

  - Includes config for extra filters (thnks to [@dadittoz](https://github.com/holli/auto_strip_attributes/issues/1))

## [1.0] - 2011-08-26

  - Only basic filters
