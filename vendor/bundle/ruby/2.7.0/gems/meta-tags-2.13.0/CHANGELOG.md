## 2.13.0 (October 10, 2019) [☰](https://github.com/kpumuk/meta-tags/compare/v2.12.0...v2.13.0)

Bugfixes:
  - Fixed Rails 6 deprecation warning.

## 2.12.0 (September 10, 2019) [☰](https://github.com/kpumuk/meta-tags/compare/v2.11.1...v2.12.0)

Features:
  - Indexing directives (`noindex`, `nofollow`, etc. now support an array of robot names as a value).
  - Added support for `link[rel='manifest']` ([199](https://github.com/kpumuk/meta-tags/pull/199))

Bugfixes:
  - When `noindex` uses "robots" as a value, `nofollow` ignores a custom robot name, and switches to "robots" as well

## 2.11.1 (January 19, 2019) [☰](https://github.com/kpumuk/meta-tags/compare/v2.11.0...v2.11.1)

Features:
  - Rails 6 is officially supported.

## 2.11.0 (November 16, 2018) [☰](https://github.com/kpumuk/meta-tags/compare/v2.10.0...v2.11.0)

Features:
  - Added a configuration option `minify_output` to remove new line characters between meta tags ([182](https://github.com/kpumuk/meta-tags/pull/182))
  - Title, description, and keywords can be an object responding to `#to_str` ([183](https://github.com/kpumuk/meta-tags/pull/183))

Bugfixes:
  - Truncate title before escaping HTML characters ([180](https://github.com/kpumuk/meta-tags/pull/180))

## 2.10.0 (June 8, 2018) [☰](https://github.com/kpumuk/meta-tags/compare/v2.9.0...v2.10.0)

Features:
  - Allow `MetaTagsCollection#update` to receive an object ([169](https://github.com/kpumuk/meta-tags/pull/169))

## 2.9.0 (March 29, 2018) [☰](https://github.com/kpumuk/meta-tags/compare/v2.8.0...v2.9.0)

Features:
  - Added ability to add `index` robots meta tag (thanks to @rafallo)

## 2.8.0 (February 28, 2018) [☰](https://github.com/kpumuk/meta-tags/compare/v2.7.1...v2.8.0)

Features:
  - Added noarchive support.

Changes:
  - Updated default description size to 300 as a new recommended truncation limit.

## 2.7.1 (February 1, 2018) [☰](https://github.com/kpumuk/meta-tags/compare/v2.7.0...v2.7.1)

Changes:
  - Properly generate Open Graph meta tags for object types that fail to provide a proper scope (e.g. `restaurant:contact_info` metadata for `restaurant:restaurant` object type).

Bugfixes:
  - Description truncated to empty string and removed from meta tags when limit is set to `0` (while documentation suggests we should remove limits in this case).

## 2.7.0 (November 22, 2017) [☰](https://github.com/kpumuk/meta-tags/compare/v2.6.0...v2.7.0)

Changes:
  - Generate open meta tags (`<meta ... >`) instead of closed meta tags (`<meta ... />`) by default, which is . Added a new option to switch back to self-closing meta tags, which are valid in HTML5, but unnecessary.

## 2.6.0 (August 24, 2017) [☰](https://github.com/kpumuk/meta-tags/compare/v2.5.0...v2.6.0)

Features:
  - Optionally avoid downcasing keywords
  - Added Rails generator to create an initializer with the default settings.
  - Added a configuration option `truncate_site_title_first` which enables site title truncation when title limit is reached.
  - When `Time`, `Date`, or `DateTime` passed as a meta tag value, it will be formatted according to ISO 8601.

Bugfixes:
  - When title limit reached with `reverse` set to `true`, properly truncate the last item of the title array instead of the first one.
  - Do not merge title and site title for OpenGraph, site title is available for reference as `:site`, and full title as `:full_title`.

Changes:
  - Removed Google "author" and "publisher" links, as Google deprecated these options (https://support.google.com/webmasters/answer/6083347?hl=en)

## 2.5.0 (August 23, 2017) [☰](https://github.com/kpumuk/meta-tags/compare/v2.4.1...v2.5.0)

Features:
  - Fully support [Open Graph objects](https://developers.facebook.com/docs/reference/opengraph) meta tags.

Changes:
  - Dropped official support for Rails older than 4.2 and Ruby older than 2.2 (both reached their End of Life)

## 2.4.1 (May 15, 2017) [☰](https://github.com/kpumuk/meta-tags/compare/v2.4.0...v2.4.1)

Features:
  - Rails 5.1 support added

## 2.4.0 (December 8, 2016) [☰](https://github.com/kpumuk/meta-tags/compare/v2.3.1...v2.4.0)

Features:
  - Added amphtml links support

Bugfixes:
  - Fixed `place` attribute meta tag generation

## 2.3.1 (September 13, 2016) [☰](https://github.com/kpumuk/meta-tags/compare/v2.2.0...v2.3.1)

Changes:
  - Added follow meta tag support

Features:
  - Added support for article meta tags

## 2.2.0 (August 24, 2016) [☰](https://github.com/kpumuk/meta-tags/compare/v2.1.0...v2.2.0)

Changes:

  - Rails < 3.2 is not longer supported

Features:

  - Added support for `<link rel="image_src" href="...">` tag
  - Added support for App Links
  - Added support for `follow` meta tag

Bugfixes:

  - Fixed double escaping for ampersands (thanks to @srecnig)
  - Removed usage of `alias_method_chain` to fix deprecation warnings with Rails 5
  - Fixed the issue when title was truncated in some cases, when site_title was blank
  - Fixed meta tag attributes for `fb:` meta tags

## 2.1.0 (October 6, 2015) [☰](https://github.com/kpumuk/meta-tags/compare/v2.0.0...v2.1.0)

Changes:

  - Ruby < 2.0 is not longer supported

Features:

  - Added charset meta tag
  - Added ability to configure limits for title, description, keywords
  - Added OpenSearch links support
  - Added icon links support
  - Alternate links can now be generated for RSS or mobile versions

Bugfixes
  - Generate `<meta name=""/>` instead of `<meta property=""/>` for custom meta tags
  - Double HTML escaping in meta tags

## 2.0.0 (April 15, 2014) [☰](https://github.com/kpumuk/meta-tags/compare/v1.6.0...v2.0.0)

Features:

  - Fully refactored code base.

Bugfixes:

  - Symlink references in nested hashes include use normalized meta tag values.

## 1.6.0 (April 14, 2014) [☰](https://github.com/kpumuk/meta-tags/compare/v1.5.0...v1.6.0)

Features:

  - Added "alternate" links support
  - Added Google "author" and "publisher" links
  - Implemented mirrored values inside namespaces declared as hashes

Breaking changes:

  - Removed support of Rails older than 3.0.0 due to the bug in `Hash#deep_merge` (does not support `HashWithIndifferentAccess`)

## 1.5.0 (May 7, 2013) [☰](https://github.com/kpumuk/meta-tags/compare/v1.4.1...v1.5.0)

Features:

  - Added "prev" and "next" links support
  - Added refresh meta tag support

## 1.4.1 (March 14, 2013) [☰](https://github.com/kpumuk/meta-tags/compare/v1.4.0...v1.4.1)

Bugfixes:

  - Added support for Hash inside of an Array

## 1.4.0 (March 14, 2013) [☰](https://github.com/kpumuk/meta-tags/compare/v1.3.0...v1.4.0)

Features:

  - Added support of custom meta tags

## 1.3.0 (February 13, 2013) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.6...v1.3.0)

Features:

  - Added Hash and Array as possible contents for the meta tags. Check README for details
  - Added support of string meta tag names
  - Allow to disable noindex and nofollow using `false` as a value

Bugfixes:

  - Do not display title HTML tag when title is blank
  - Do not display OpenGraph tags when content is empty

## 1.2.6 (March 4, 2012) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.5...v1.2.6)

Features:

  - jQuery.pjax support via `display_title` method. Check README for details

## 1.2.5 (March 3, 2012) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.4...v1.2.5)

Bugfixes:

  - Fixed bug with overriding open graph attributes
  - Fixed incorrect page title when `:site` is is blank
  - Normalize `:og` attribute to `:open_graph`

## 1.2.4 (April 26, 2011) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.3...v1.2.4)

Features:

  - Added support for Open Graph meta tags

Bugfixes:

  - Fixed bug with double HTML escaping in title separator
  - Allow to set meta title without a separator

## 1.2.2, 1.2.3 (June 10, 2010) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.1...v1.2.3)

Bugfixes:

  - Fixed action\_pack integration (welcome back `alias_method_chain`)
  - Fixed bug when `@page_*` variables did not work

## 1.2.1 (June 2, 2010) [☰](https://github.com/kpumuk/meta-tags/compare/v1.2.0...v1.2.1)

Bugfixes:

  - Fixed deprecation warning about `html_safe!`

## 1.2.0 (May 31, 2010) [☰](https://github.com/kpumuk/meta-tags/compare/v1.1.1...v1.2.0)

Bugfixes:

  - Fixed bug when title is set through Array, and `:lowercase` is true
  - Updated `display_meta_tags` to be compatible with rails_xss

## 1.1.1 (November 21, 2009) [☰](https://github.com/kpumuk/meta-tags/compare/v1.1.0...v1.1.1)

Features:

  - Added support for canonical link element
  - Added YARD documentation

## 1.1.0 (November 5, 2009) [☰](https://github.com/kpumuk/meta-tags/commits/v1.1.0)

Features:

  - Added ability to specify title as an Array of parts
  - Added helper for `noindex`
  - Added `nofollow` meta tag support

Bugfixes:

  - Fixed Rails 2.3 deprecation warnings
