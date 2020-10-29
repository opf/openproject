# PDF::Inspector: A tool for analyzing PDF output

![Maintained: yes](https://img.shields.io/badge/maintained-yes-brightgreen.svg)
![Build status](https://travis-ci.org/prawnpdf/pdf-inspector.svg?branch=master)

This library provides a number of [PDF::Reader][0] based tools for use in
testing PDF output.  Presently, the primary purpose of this tool is to support
the tests found in [Prawn][1], a pure Ruby PDF generation library.

However, it may be useful to others, so we have made it available as a gem in
its own right.

## Installation

The recommended installation method is via Rubygems.

```console
gem install pdf-inspector
```

Or put this in your Gemfile, if you use [Bundler][2]:

```ruby
group :test do
  gem 'pdf-inspector', require: "pdf/inspector"
end
```

## Usage

Check for text in the generated PDF:

```ruby
rendered_pdf = your_pdf_document.render
text_analysis = PDF::Inspector::Text.analyze(rendered_pdf)
text_analysis.strings # => ["foo"]
```

Note that `strings` returns an array containing one string for each text drawing
operation in the PDF. As a result, sentences and paragraphs will often be
returned in fragments. To test for the presence of a complete sentence or a
longer string, join the array together with an operation like `full_text =
text_analysis.strings.join(" ")`.

Check number of pages

```ruby
rendered_pdf = your_pdf_document.render
page_analysis = PDF::Inspector::Page.analyze(rendered_pdf)
page_analysis.pages.size # => 2
```

## Licensing

Matz’s terms for Ruby, GPLv2, or GPLv3. See LICENSE for details.

## Mailing List

pdf-inspector is maintained as a dependency of Prawn, the ruby PDF generation
library.

Any questions or feedback should be sent to the [Prawn google group][3].

## Authorship

pdf-inspector was originally developed by Gregory Brown as part of the Prawn[1]
project. In 2010, Gregory officially handed the project off to the Prawn core
team. Currently active maintainers include Brad Ediger, Daniel Nelson, James
Healy, and Jonathan Greenberg.

You can find the full list of Github users who have at least one patch accepted
to pdf-inspector on [GitHub Contributors page][4].



[0]: https://github.com/yob/pdf-reader
[1]: https://github.com/prawnpdf/prawn
[2]: https://bundler.io/
[3]: https://groups.google.com/group/prawn-ruby
[4]: https://github.com/prawnpdf/pdf-inspector/contributors
