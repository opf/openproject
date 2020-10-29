# Spreadsheet
## Getting Started
[![Join the chat at https://gitter.im/zdavatz/spreadsheet](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/zdavatz/spreadsheet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://secure.travis-ci.org/zdavatz/spreadsheet.png)](http://travis-ci.org/zdavatz/spreadsheet)

The Mailing List can be found here:

http://groups.google.com/group/rubyspreadsheet

The code can be found here:

https://github.com/zdavatz/spreadsheet

For Non-GPLv3 commercial licensing, please see:

http://www.spreadsheet.ch

## XLS Binary Documentation
* https://github.com/zdavatz/spreadsheet/blob/master/Excel97-2007BinaryFileFormatSpecification.pdf
* https://github.com/zdavatz/spreadsheet/blob/master/excelfileformat.pdf

## Description

The Spreadsheet Library is designed to read and write Spreadsheet Documents.
As of version 0.6.0, only Microsoft Excel compatible spreadsheets are
supported. Spreadsheet is a combination/complete rewrite of the
Spreadsheet::Excel Library by Daniel J. Berger and the ParseExcel Library by
Hannes Wyss. Spreadsheet can read, write and modify Spreadsheet Documents.

## Notes from Users

* [Alfred](mailto:a@boxbot.org): The library doesn't recognize cell formats in Excel
created documents, which results in Floats returned for any number.
* [Tom](https://github.com/tom-lord): This library *only* supports XLS format;
it does **not** support XLSX format.

## What's new?

* Supported outline (grouping) functions
* Significantly improved memory-efficiency when reading large Excel Files
* Limited Spreadsheet modification support
* Improved handling of String Encodings


## On the Roadmap

* Improved Format support/Styles
* Document Modification: Formats/Styles
* Formula Support
* Document Modification: Formulas
* Write-Support: BIFF5
* Remove backward compatibility code

Note: Spreadsheet is tested against all minor ruby versions through: 1.8.7 - 2.6.3

You will get a deprecated warning about iconv when using spreadsheet with Ruby
1.9.3. So replacing iconv is on the Roadmap as well ;).

## Dependencies

* [ruby-ole](http://code.google.com/p/ruby-ole/)


## Examples

* Have a look at the [GUIDE](https://github.com/zdavatz/spreadsheet/blob/master/GUIDE.md)
* Also look at: https://gist.github.com/phollyer/1214475

## Installation

Using [RubyGems](http://www.rubygems.org):

* `sudo gem install spreadsheet`

If you don't like [RubyGems](http://www.rubygems.org), let me know which
installation solution you prefer and I'll include it in the future.

If you can use 'rake' and 'hoe' library is also installed, you can 
build a gem package as follows:

* `rake gem`

The gem package is built in pkg directory.

## Testing

Bundler support added.
Running tests:
* `bundle install`
* ./test/suite.rb

## TravisCI 

* https://travis-ci.org/zdavatz/spreadsheet

## Authors

Original Code:

Spreadsheet::Excel:
Copyright (c) 2005 by Daniel J. Berger (djberg96@gmail.com)

ParseExcel:
Copyright (c) 2003 by Hannes Wyss (hannes.wyss@gmail.com)

New Code:
Copyright (c) 2010 ywesee GmbH (mhatakeyama@ywesee.com, zdavatz@ywesee.com)


## License

This library is distributed under the GPLv3.
Please see the [LICENSE](https://github.com/zdavatz/spreadsheet/blob/master/LICENSE.txt) file.

