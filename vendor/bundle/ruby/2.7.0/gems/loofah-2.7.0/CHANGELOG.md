# Changelog

## 2.7.0 / 2020-08-26

### Features

* Allow CSS properties `page-break-before`, `page-break-inside`, and `page-break-after`. [[#190](https://github.com/flavorjones/loofah/issues/190)] (Thanks, [@ahorek](https://github.com/ahorek)!)


### Fixes

* Don't drop the `!important` rule from some CSS properties. [[#191](https://github.com/flavorjones/loofah/issues/191)] (Thanks, [@b7kich](https://github.com/b7kich)!)


## 2.6.0 / 2020-06-16

### Features

* Allow CSS `border-style` keywords. [[#188](https://github.com/flavorjones/loofah/issues/188)] (Thanks, [@tarcisiozf](https://github.com/tarcisiozf)!)


## 2.5.0 / 2020-04-05

### Features

* Allow more CSS length units: "ch", "vw", "vh", "Q", "lh", "vmin", "vmax". [[#178](https://github.com/flavorjones/loofah/issues/178)] (Thanks, [@JuanitoFatas](https://github.com/JuanitoFatas)!)


### Fixes

* Remove comments from `Loofah::HTML::Document`s that exist outside the `html` element. [[#80](https://github.com/flavorjones/loofah/issues/80)]


### Other changes

* Gem metadata being set [[#181](https://github.com/flavorjones/loofah/issues/181)] (Thanks, [@JuanitoFatas](https://github.com/JuanitoFatas)!)
* Test files removed from gem file [[#180](https://github.com/flavorjones/loofah/issues/180),[#166](https://github.com/flavorjones/loofah/issues/166),[#159](https://github.com/flavorjones/loofah/issues/159)] (Thanks, [@JuanitoFatas](https://github.com/JuanitoFatas) and [@greysteil](https://github.com/greysteil)!)


## 2.4.0 / 2019-11-25

### Features

* Allow CSS property `max-width` [[#175](https://github.com/flavorjones/loofah/issues/175)] (Thanks, [@bchaney](https://github.com/bchaney)!)
* Allow CSS sizes expressed in `rem` [[#176](https://github.com/flavorjones/loofah/issues/176), [#177](https://github.com/flavorjones/loofah/issues/177)]
* Add `frozen_string_literal: true` magic comment to all `lib` files. [[#118](https://github.com/flavorjones/loofah/issues/118)]


## 2.3.1 / 2019-10-22

### Security

Address CVE-2019-15587: Unsanitized JavaScript may occur in sanitized output when a crafted SVG element is republished.

This CVE's public notice is at [#171](https://github.com/flavorjones/loofah/issues/171)


## 2.3.0 / 2019-09-28

### Features

* Expand set of allowed protocols to include `tel:` and `line:`. [[#104](https://github.com/flavorjones/loofah/issues/104), [#147](https://github.com/flavorjones/loofah/issues/147)]
* Expand set of allowed CSS functions. [related to [#122](https://github.com/flavorjones/loofah/issues/122)]
* Allow greater precision in shorthand CSS values. [[#149](https://github.com/flavorjones/loofah/issues/149)] (Thanks, [@danfstucky](https://github.com/danfstucky)!)
* Allow CSS property `list-style` [[#162](https://github.com/flavorjones/loofah/issues/162)] (Thanks, [@jaredbeck](https://github.com/jaredbeck)!)
* Allow CSS keywords `thick` and `thin` [[#168](https://github.com/flavorjones/loofah/issues/168)] (Thanks, [@georgeclaghorn](https://github.com/georgeclaghorn)!)
* Allow HTML property `contenteditable` [[#167](https://github.com/flavorjones/loofah/issues/167)] (Thanks, [@andreynering](https://github.com/andreynering)!)


### Bug fixes

* CSS hex values are no longer limited to lowercase hex. Previously uppercase hex were scrubbed. [[#165](https://github.com/flavorjones/loofah/issues/165)] (Thanks, [@asok](https://github.com/asok)!)


### Deprecations / Name Changes

The following method and constants are hereby deprecated, and will be completely removed in a future release:

* Deprecate `Loofah::Helpers::ActionView.white_list_sanitizer`, please use `Loofah::Helpers::ActionView.safe_list_sanitizer` instead.
* Deprecate `Loofah::Helpers::ActionView::WhiteListSanitizer`, please use `Loofah::Helpers::ActionView::SafeListSanitizer` instead.
* Deprecate `Loofah::HTML5::WhiteList`, please use `Loofah::HTML5::SafeList` instead.

Thanks to [@JuanitoFatas](https://github.com/JuanitoFatas) for submitting these changes in [#164](https://github.com/flavorjones/loofah/issues/164) and for making the language used in Loofah more inclusive.


## 2.2.3 / 2018-10-30

### Security

Address CVE-2018-16468: Unsanitized JavaScript may occur in sanitized output when a crafted SVG element is republished.

This CVE's public notice is at [#154](https://github.com/flavorjones/loofah/issues/154)


## Meta / 2018-10-27

The mailing list is now on Google Groups [#146](https://github.com/flavorjones/loofah/issues/146):

* Mail: loofah-talk@googlegroups.com
* Archive: https://groups.google.com/forum/#!forum/loofah-talk

This change was made because librelist no longer appears to be maintained.


## 2.2.2 / 2018-03-22

Make public `Loofah::HTML5::Scrub.force_correct_attribute_escaping!`,
which was previously a private method. This is so that downstream gems
(like rails-html-sanitizer) can use this logic directly for their own
attribute scrubbers should they need to address CVE-2018-8048.


## 2.2.1 / 2018-03-19

### Security

Addresses CVE-2018-8048. Loofah allowed non-whitelisted attributes to be present in sanitized output when input with specially-crafted HTML fragments.

This CVE's public notice is at [#144](https://github.com/flavorjones/loofah/issues/144)


## 2.2.0 / 2018-02-11

### Features:

* Support HTML5 `<main>` tag. [#133](https://github.com/flavorjones/loofah/issues/133) (Thanks, [@MothOnMars](https://github.com/MothOnMars)!)
* Recognize HTML5 block elements. [#136](https://github.com/flavorjones/loofah/issues/136) (Thanks, [@MothOnMars](https://github.com/MothOnMars)!)
* Support SVG `<symbol>` tag. [#131](https://github.com/flavorjones/loofah/issues/131) (Thanks, [@baopham](https://github.com/baopham)!)
* Support for whitelisting CSS functions, initially just `calc` and `rgb`. [#122](https://github.com/flavorjones/loofah/issues/122)/[#123](https://github.com/flavorjones/loofah/issues/123)/[#129](https://github.com/flavorjones/loofah/issues/129) (Thanks, [@NikoRoberts](https://github.com/NikoRoberts)!)
* Whitelist CSS property `list-style-type`. [#68](https://github.com/flavorjones/loofah/issues/68)/[#137](https://github.com/flavorjones/loofah/issues/137)/[#142](https://github.com/flavorjones/loofah/issues/142) (Thanks, [@andela-ysanni](https://github.com/andela-ysanni) and [@NikoRoberts](https://github.com/NikoRoberts)!)

### Bugfixes:

* Properly handle nested `script` tags. [#127](https://github.com/flavorjones/loofah/issues/127).


## 2.1.1 / 2017-09-24

### Bugfixes:

* Removed warning for unused variable. [#124](https://github.com/flavorjones/loofah/issues/124) (Thanks, [@y-yagi](https://github.com/y-yagi)!)


## 2.1.0 / 2017-09-24

### Notes:

* Re-implemented CSS parsing and sanitization using the [crass](https://github.com/rgrove/crass) library. [#91](https://github.com/flavorjones/loofah/issues/91)


### Features:

* Added :noopener HTML scrubber (Thanks, [@tastycode](https://github.com/tastycode)!)
* Support `data` URIs with the following media types: text/plain, text/css, image/png, image/gif, image/jpeg, image/svg+xml. [#101](https://github.com/flavorjones/loofah/issues/101), [#120](https://github.com/flavorjones/loofah/issues/120). (Thanks, [@mrpasquini](https://github.com/mrpasquini)!)


### Bugfixes:

* The :unprintable scrubber now scrubs unprintable characters in CDATA nodes (like `<script>`). [#124](https://github.com/flavorjones/loofah/issues/124)
* Allow negative values in CSS properties. Restores functionality that was reverted in v2.0.3. [#91](https://github.com/flavorjones/loofah/issues/91)


## 2.0.3 / 2015-08-17

### Bug fixes:

* Revert support for negative values in CSS properties due to slow performance. [#90](https://github.com/flavorjones/loofah/issues/90) (Related to [#85](https://github.com/flavorjones/loofah/issues/85).)


## 2.0.2 / 2015-05-05

### Bug fixes:

* Fix error with `#to_text` when Loofah::Helpers hadn't been required. [#75](https://github.com/flavorjones/loofah/issues/75)
* Allow multi-word data attributes. [#84](https://github.com/flavorjones/loofah/issues/84) (Thanks, [@jstorimer](https://github.com/jstorimer)!)
* Allow negative values in CSS properties. [#85](https://github.com/flavorjones/loofah/issues/85) (Thanks, [@siddhartham](https://github.com/siddhartham)!)


## 2.0.1 / 2014-08-21

### Bug fixes:

* Load RR correctly when running test files directly. (Thanks, [@ktdreyer](https://github.com/ktdreyer)!)


### Notes:

* Extracted HTML5::Scrub#scrub_css_attribute to accommodate the Rails integration work. (Thanks, [@kaspth](https://github.com/kaspth)!)


## 2.0.0 / 2014-05-09

### Compatibility notes:

* ActionView helpers now must be required explicitly: `require "loofah/helpers"`
* Support for Ruby 1.8.7 and prior has been dropped

### Enhancements:

* HTML5 whitelist allows the following ...
  * tags: `article`, `aside`, `bdi`, `bdo`, `canvas`, `command`, `datalist`, `details`, `figcaption`, `figure`, `footer`, `header`, `mark`, `meter`, `nav`, `output`, `section`, `summary`, `time`
  * attributes: `data-*` (Thanks, Rafael Franca!)
  * URI attributes: `poster` and `preload`
* Addition of the `:unprintable` scrubber to remove unprintable characters from text nodes. [#65](https://github.com/flavorjones/loofah/issues/65) (Thanks, Matt Swanson!)
* `Loofah.fragment` accepts an optional encoding argument, compatible with `Nokogiri::HTML::DocumentFragment.parse`. [#62](https://github.com/flavorjones/loofah/issues/62) (Thanks, Ben Atkins!)
* HTML5 sanitizers now remove attributes without values. (Thanks, Kasper Timm Hansen!)

### Bug fixes:

* HTML5 sanitizers' CSS keyword check now actually works (broken in v2.0). Additional regression tests added. (Thanks, Kasper Timm Hansen!)
* HTML5 sanitizers now allow negative arguments to CSS. [#64](https://github.com/flavorjones/loofah/issues/64) (Thanks, Jon Calhoun!)


## 1.2.1 (2012-04-14)

* Declaring encoding in html5/scrub.rb. Without this, use of the ruby -KU option would cause havoc. ([#32](https://github.com/flavorjones/loofah/issues/32))


## 1.2.0 (2011-08-08)

### Enhancements:

* Loofah::Helpers.sanitize_css is a replacement for Rails's built-in sanitize_css helper.
* Improving ActionView integration.


## 1.1.0 (2011-08-08)

### Enhancements:

* Additional HTML5lib whitelist elements (from html5lib 1524:80b5efe26230).
  Up to date with HTML5lib ruby code as of 1723:7ee6a0331856.
* Whitelists (which are not part of the public API) are now Sets (were previously Arrays).
* Don't explode when encountering UTF-8 URIs. ([#25](https://github.com/flavorjones/loofah/issues/25), [#29](https://github.com/flavorjones/loofah/issues/29))


## 1.0.0 (2010-10-26)

### Notes:

* Moved ActiveRecord functionality into `loofah-activerecord` gem.
* Removed DEPRECATIONS.rdoc documenting 0.3.0 API changes.


## 0.4.7 (2010-03-09)

### Enhancements:

* New methods Loofah::HTML::Document#to_text and
  Loofah::HTML::DocumentFragment#to_text do the right thing with
  whitespace. Note that these methods are significantly slower than
  #text. GH [#12](https://github.com/flavorjones/loofah/issues/12)
* Loofah::Elements::BLOCK_LEVEL contains a canonical list of HTML4 block-level4 elements.
* Loofah::HTML::Document#text and Loofah::HTML::DocumentFragment#text
  will return unescaped HTML entities by passing :encode_special_chars => false.


## 0.4.4, 0.4.5, 0.4.6 (2010-02-01)

### Enhancements:

* Loofah::HTML::Document#text and Loofah::HTML::DocumentFragment#text now escape HTML entities.

### Bug fixes:

* Loofah::XssFoliate was not properly escaping HTML entities when implicitly scrubbing a string attribute. GH [#17](https://github.com/flavorjones/loofah/issues/17)


## 0.4.3 (2010-01-29)

### Enhancements:

* All built-in scrubbers are accepted by ActiveRecord::Base.xss_foliate
* Loofah::XssFoliate.xss_foliate_all_models replaces use of the constant LOOFAH_XSS_FOLIATE_ALL_MODELS

### Miscellaneous:

* Modified documentation for bootstrapping XssFoliate in a Rails app,
  since the use of Bundler breaks the previously-documented method. To
  be safe, always use an initializer file.


## 0.4.2 (2010-01-22)

### Enhancements:

* Implemented Node#scrub! for scrubbing subtrees.
* Implemented NodeSet#scrub! for scrubbing a set of subtrees.
* Document.text now only serializes <body> contents (ignores <head>)
* <head>, <html> and <body> added to the HTML5lib whitelist.

### Bug fixes:

* Supporting Rails apps that aren't loading ActiveRecord. GH [#10](https://github.com/flavorjones/loofah/issues/10)

### Miscellaneous:

* Mailing list is now loofah@librelist.com / http://librelist.com
* IRC channel is now \#loofah on freenode.


## 0.4.1 (2009-11-23)

### Bugfix:

* Manifest fixed. Whoops.


## 0.4.0 (2009-11-21)

### Enhancements:

* Scrubber class introduced, allowing development of custom scrubbers.
* Added support for XML documents and fragments.
* Added :nofollow HTML scrubber (thanks Luke Melia!)
* Built-in scrubbing methods refactored to use Scrubber.



## 0.3.1 (2009-10-12)

### Bug fixes:

* Scrubbed Documents properly render html, head and body tags when serialized.


## 0.3.0 (2009-10-06)

### Enhancements:

* New ActiveRecord extension `xss_foliate`, a drop-in replacement for xss_terminate[http://github.com/look/xss_terminate/tree/master].
* Replacement methods for Rails's helpers, Loofah::Rails.sanitize and Loofah::Rails.strip_tags.
* Official support (and test coverage) for Rails versions 2.3, 2.2, 2.1, 2.0 and 1.2.

### Deprecations:

* The methods strip_tags, whitewash, whitewash_document, sanitize, and
  sanitize_document have been deprecated. See DEPRECATED.rdoc for
  details on the equivalent calls with the post-0.2 API.


## 0.2.2 (2009-09-30)

### Enhancements:

* ActiveRecord extension scrubs fields in a before_validation callback
  (was previously in a before_save)


## 0.2.1 (2009-09-19)

### Enhancements:

* when loaded in a Rails app, automatically extend ActiveRecord::Base
  with html_fragment and html_document. GH [#6](https://github.com/flavorjones/loofah/issues/6) (Thanks Josh Nichols!)

### Bugfixes:

* ActiveRecord scrubbing should generate strings instead of Document or
  DocumentFragment objects. GH [#5](https://github.com/flavorjones/loofah/issues/5)
* init.rb fixed to support installation as a Rails plugin. GH [#6](https://github.com/flavorjones/loofah/issues/6)
  (Thanks Josh Nichols!)


## 0.2.0 (2009-09-11)

* Swank new API.
* ActiveRecord extension.
* Uses Nokogiri's Document and DocumentFragment for parsing.
* Updated html5lib codes and tests to revision 1384:b9d3153d7be7.
* Deprecated the Dryopteris sanitization methods. Will be removed in 0.3.0.
* Documentation! Hey!


## 0.1.2 (2009-04-30)

* Added whitewashing -- removal of all attributes and namespaced nodes. You know, for microsofty HTML.


## 0.1.0 (2009-02-10)

* Birthday!
