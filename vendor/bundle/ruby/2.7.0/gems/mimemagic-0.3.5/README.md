MimeMagic is a library to detect the mime type of a file by extension or by content. It uses the mime database
provided by freedesktop.org (see http://freedesktop.org/wiki/Software/shared-mime-info/).

[![Gem Version](https://img.shields.io/gem/v/mimemagic.svg)](http://rubygems.org/gems/mimemagic)
[![Gem Downloads](https://img.shields.io/gem/dt/mimemagic.svg)](http://rubygems.org/gems/mimemagic)
[![Build Status](https://secure.travis-ci.org/minad/mimemagic.svg?branch=master)](http://travis-ci.org/minad/mimemagic) [![Code Climate](https://codeclimate.com/github/minad/mimemagic.svg)](https://codeclimate.com/github/minad/mimemagic)
[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=min4d&url=https://github.com/minad/mimemagic&title=MimeMagic&language=&tags=github&category=software)

Usage
=====

```ruby
require 'mimemagic'
MimeMagic.by_extension('html').text?
MimeMagic.by_extension('.html').child_of? 'text/plain'
MimeMagic.by_path('filename.txt')
MimeMagic.by_magic(File.open('test.html'))
# etc...
```

Extra magic overlay
=====

Microsoft Office 2007+ formats (xlsx, docx, and pptx) are not supported by the mime database at freedesktop.org. These files are all zipped collections of xml files and will be detected as "application/zip". Mimemagic comes with extra magic you can overlay on top of the defaults to correctly detect these file types. Enable it like this:

```ruby
require 'mimemagic'
require 'mimemagic/overlay'
MimeMagic.by_magic(File.open('test.xlsx'))
```

You can add your own magic with `MimeMagic.add`. See `lib/mimemagic/overlay.rb`.

API
===

http://www.rubydoc.info/github/minad/mimemagic

Tests
=====

```
bundle install

rake test
```

Authors
=======

Daniel Mendler
