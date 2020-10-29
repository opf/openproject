# Prawn::Markup

[![Build Status](https://travis-ci.org/puzzle/prawn-markup.svg?branch=master)](https://travis-ci.org/puzzle/prawn-markup)
[![Maintainability](https://api.codeclimate.com/v1/badges/52a462f9d65e33352d4e/maintainability)](https://codeclimate.com/github/puzzle/prawn-markup/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/52a462f9d65e33352d4e/test_coverage)](https://codeclimate.com/github/puzzle/prawn-markup/test_coverage)

Adds simple HTML snippets into [Prawn](http://prawnpdf.org)-generated PDFs. All elements are layouted vertically using Prawn's formatting options. A major use case for this gem is to include WYSIWYG-generated HTML parts into server-generated PDF documents.

This gem does not and will never convert entire HTML + CSS pages to PDF. Use [wkhtmltopdf](https://wkhtmltopdf.org/) for that. Have a look at the details of the [Supported HTML](#supported-html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prawn-markup'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prawn-markup

## Usage

In your prawn Document, add HTML like this:

```ruby
doc = Prawn::Document.new
doc.markup('<p>Hello World</p><hr/><p>KTHXBYE</p>')
```

## Supported HTML

This gem parses the given HTML and layouts the following elements in a vertical order:

* Text blocks: `p`, `div`, `ol`, `ul`, `li`, `hr`, `br`
* Text semantics: `a`, `b`, `strong`, `i`, `em`, `u`, `s`, `del`, `sub`, `sup`
* Headings: `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
* Tables: `table`, `tr`, `td`, `th`
* Media: `img`, `iframe`
* Inputs: `type=checkbox`, `type=radio`

All other elements are ignored, their content is added to the parent element. With a few exceptions, no CSS is processed. One exception is the `width` property of `img`, `td` and `th`, which may contain values in `cm`, `mm`, `px`, `pt`, `%` or `auto`.

If no explicit loader is given (see above), images are loaded from `http(s)` addresses or may be contained in the `src` attribute as base64 encoded data URIs. Prawn only supports `PNG` and `JPG`.

## Example

Have a look at [showcase.html](spec/fixtures/showcase.html), which is rendered by the corresponding [spec](spec/prawn/markup/showcase_spec.rb). Uncomment the `lookatit` call there to directly open the generated PDF when running the spec with `spec spec/prawn/markup/showcase_spec.rb`.

## Formatting Options

To customize element formatting, do:

```ruby
doc = Prawn::Document.new
# set options for the entire document
doc.markup_options = {
  text: { font: 'Times' },
  table: { header: { style: :bold, background_color: 'FFFFDD' } }
}
# set additional options for each single call
doc.markup('<p>Hello World</p><hr/><p>KTHXBYE</p>', text: { align: :center })
```

Options may be set for `text`, `heading[1-6]`, `table` (subkeys `cell` and `header`) and `list` (subkeys `content` and `bullet`).

Text and heading options include all keys from Prawns [#text](http://prawnpdf.org/api-docs/2.0/Prawn/Text.html#text-instance_method) method: `font`, `size`, `color`, `style`, `align`, `valign`, `leading`,`direction`, `character_spacing`, `indent_paragraphs`, `kerning`, `mode`.

Tables and lists are rendered with [prawn-table](https://github.com/prawnpdf/prawn-table) and have the following additional options: `padding`, `borders`, `border_width`, `border_color`, `background_color`, `border_lines`, `rotate`, `overflow`, `min_font_size`. Options from `text` may be overridden.

Beside these options handled by Prawn / prawn-table, the following values may be customized:

* `:text`
  * `:preprocessor`: A proc/callable that is called each time before a chunk of text is rendered.
  * `:margin_bottom`: Margin after each `<p>`, `<ol>`, `<ul>` or `<table>`. Defaults to about half a line.
* `:heading1-6`
  * `:margin_top`: Margin before a heading. Default is 0.
  * `:margin_bottom`: Margin after a heading. Default is 0.
* `:table`
  * `:placeholder`
    * `:too_large`: If the table content does not fit into the current bounding box, this text/callable is rendered instead. Defaults to '[table content too large]'.
    * `:subtable_too_large`: If the content of a subtable cannot be fitted into the table, this text is rendered instead. Defaults to '[nested tables with automatic width are not supported]'.
* `:list`
  * `:vertical_margin`: Margin at the top and the bottom of a list. Default is 5.
  * `:bullet`
    * `:char`: The text used as bullet in unordered lists. Default is '•'.
    * `:margin`: Margin before the bullet. Default is 10.
  * `:content`
    * `:margin`: Margin between the bullet and the content. Default is 10.
  * `:placeholder`
    * `:too_large`: If the list content does not fit into the current bounding box, this text/callable is rendered instead. Defaults to '[list content too large]'.
* `:image`
  * `:loader`: A callable that accepts the `src` attribute as an argument an returns a value understood by Prawn's `image` method. Loads `http(s)` URLs and base64 encoded data URIs by default.
  * `:placeholder`: If an image is not supported, this text/callable is rendered instead. Defaults to '[unsupported image]'.
* `:iframe`
  * `:placeholder`: If the HTML contains IFrames, this text/callable is rendered instead.
  A callable gets the URL of the IFrame as an argument. Defaults to ignore iframes.
* `:input`
  * `:symbol_font`: A special font to print checkboxes and radios. Prawn's standard fonts do not support special unicode characters. Do not forget to update the document's `font_families`.
  * `:symbol_font_size`: The size of the special font to print checkboxes and radios.
  * `:checkbox`
    * `:checked`: The char to print for a checked checkbox. Default is '☑'.
    * `:unchecked`: The char to print for an unchecked checkbox. Default is '☐'.
  * `:radio`
    * `:checked`: The char to print for a checked radio. Default is '◉'.
    * `:unchecked`: The char to print for an unchecked radio. Default is '○'.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puzzle/prawn-markup. For pull requests, add specs, make sure all of them pass and fix all rubocop issues.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Prawn::Markup project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/puzzle/prawn-markup/blob/master/CODE_OF_CONDUCT.md).
