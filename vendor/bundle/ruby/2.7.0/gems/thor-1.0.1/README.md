Thor
====

[![Gem Version](http://img.shields.io/gem/v/thor.svg)][gem]
[![Build Status](http://img.shields.io/travis/erikhuda/thor.svg)][travis]
[![Code Climate](http://img.shields.io/codeclimate/github/erikhuda/thor.svg)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/erikhuda/thor.svg)][coveralls]

[gem]: https://rubygems.org/gems/thor
[travis]: http://travis-ci.org/erikhuda/thor
[codeclimate]: https://codeclimate.com/github/erikhuda/thor
[coveralls]: https://coveralls.io/r/erikhuda/thor

Description
-----------
Thor is a simple and efficient tool for building self-documenting command line
utilities.  It removes the pain of parsing command line options, writing
"USAGE:" banners, and can also be used as an alternative to the [Rake][rake]
build tool.  The syntax is Rake-like, so it should be familiar to most Rake
users.

Please note: Thor, by design, is a system tool created to allow seamless file and url
access, which should not receive application user input. It relies on [open-uri][open-uri],
which combined with application user input would provide a command injection attack
vector.

[rake]: https://github.com/ruby/rake
[open-uri]: https://ruby-doc.org/stdlib-2.5.1/libdoc/open-uri/rdoc/index.html

Installation
------------
    gem install thor

Usage and documentation
-----------------------
Please see the [wiki][] for basic usage and other documentation on using Thor. You can also checkout the [official homepage][homepage].

[wiki]: https://github.com/erikhuda/thor/wiki
[homepage]: http://whatisthor.com/

Contributing
------------
If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

License
-------
Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE.md
