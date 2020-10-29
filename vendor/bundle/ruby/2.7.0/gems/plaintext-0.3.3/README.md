# plaintext [![Build Status](https://travis-ci.org/planio-gmbh/plaintext.svg?branch=master)](https://travis-ci.org/planio-gmbh/plaintext)

This gem wraps command line tools to extract plain text from typical files such as

- PDF
- RTF
- MS Office
    - Word (doc, docx)
    - Excel (xsl, xslx)
    - PowerPoint (ppt, pptx)
- OpenOffice + Libre
    - Presentation
    - Text
    - Spreadsheet
- Image files (png, jpeg, tiff), such as screenshots and scanned documents, through character recognition (OCR)
- Plaintext (txt)
- Comma-separated values (csv)

## Acknowledgements

This gem bases on work by Jens Krämer / Planio, who originally provided it as a
[patch for Redmine](https://www.redmine.org/issues/306). Now, it is a collaborative effort of
both project management software providers [Planio](https://plan.io) and [OpenProject](https://openproject.org)
as both systems tackle the identical challenge to extract plain text from attachment files.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plaintext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plaintext

#### Rails

In a Rails application save `plaintext.yml.example` in `config/plaintext.yml` and overwrite the settings to 
your needs.

Then load that configuration file in an initializer. Add the following lines to `config/initializers/plaintext.rb`:

```ruby
path = Rails.root.join 'config', 'plaintext.yml'
if File.file?(path)
  config = File.read(path)
  Plaintext::Configuration.load(config)
end
````

#### Plain Ruby

Please overwrite `Plaintext::Configuration.load`.

### Linux

On linux the default configuration should work. However, make sure that the following packages are installed

    $ apt-get install catdoc unrtf poppler-utils tesseract-ocr

### Mac OS X

On Mac things are still not complete. Please help us to have the same capabilities as under Linux. Right now we cannot
extract text from presentation and spreadsheets.

Please use homebrew to install the missing command line tools.

    $ brew install unrtf poppler tesseract
    
The `plaintext.yml` should look like this:
    
```yml
pdftotext:
  - /usr/local/bin/pdftotext
  - -enc
  - UTF-8
  - __FILE__
  - '-'

unrtf:
  - /usr/local/bin/unrtf
  - --text
  - __FILE__

tesseract:
  - /usr/local/bin/tesseract
  - __FILE__
  - stdout

catdoc:
  - /usr/bin/textutil
  - -convert
  - txt
  - -stdout
  - __FILE__
```

## Usage

```ruby
# `file` is of type File.
# `content_type` is a String.
fulltext = Plaintext::Resolver.new(file, content_type).text
```

To limit the number of bytes returned (default is 4MB), set the
`max_plaintext_bytes` property on the resolver instance before calling `text`.

## License

The `plaintext` gem is free software; you can redistribute it and/or modify it under the terms of the GNU General 
Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any 
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied 
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with the plugin. If not, see
[www.gnu.org/licenses](https://www.gnu.org/licenses/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/planio-gmbh/plaintext.

