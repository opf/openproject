# Nokogumbo - a Nokogiri interface to the Gumbo HTML5 parser.

Nokogumbo provides the ability for a Ruby program to invoke the 
[Gumbo HTML5 parser](https://github.com/google/gumbo-parser#readme)
and to access the result as a
[Nokogiri::HTML::Document](http://rdoc.info/github/sparklemotion/nokogiri/Nokogiri/HTML/Document).

[![Travis-CI Build Status](https://travis-ci.org/rubys/nokogumbo.svg)](https://travis-ci.org/rubys/nokogumbo) 
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/github/rubys/nokogumbo)](https://ci.appveyor.com/project/rubys/nokogumbo/branch/master)

## Usage

```ruby
require 'nokogumbo'
doc = Nokogiri.HTML5(string)
```

To parse an HTML fragment, a `fragment` method is provided.

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.fragment(string)
```

Because HTML is often fetched via the web, a convenience interface to
HTTP get is also provided:

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.get(uri)
```

## Parsing options
The document and fragment parsing methods,
- `Nokogiri.HTML5(html, url = nil, encoding = nil, options = {})`
- `Nokogiri::HTML5.parse(html, url = nil, encoding = nil, options = {})`
- `Nokogiri::HTML5::Document.parse(html, url = nil, encoding = nil, options = {})`
- `Nokogiri::HTML5.fragment(html, encoding = nil, options = {})`
- `Nokogiri::HTML5::DocumentFragment.parse(html, encoding = nil, options = {})`
support options that are different from Nokogiri's.

The two currently supported options are `:max_errors` and `:max_tree_depth`,
described below.

### Error reporting
Nokogumbo contains an experimental parse error reporting facility. By default,
no parse errors are reported but this can be configured by passing the
`:max_errors` option to `::parse` or `::fragment`.

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
doc.errors.each do |err|
  puts(err)
end
```

This prints the following.
```
1:1: ERROR: Expected a doctype token
<span/>Hi there!</span foo=bar />
^
1:1: ERROR: Start tag of nonvoid HTML element ends with '/>', use '>'.
<span/>Hi there!</span foo=bar />
^
1:17: ERROR: End tag ends with '/>', use '>'.
<span/>Hi there!</span foo=bar />
                ^
1:17: ERROR: End tag contains attributes.
<span/>Hi there!</span foo=bar />
                ^
```

Using `max_errors: -1` results in an unlimited number of errors being
returned.

The errors returned by `#errors` are instances of
[`Nokogiri::XML::SyntaxError`](https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SyntaxError).

The [HTML
standard](https://html.spec.whatwg.org/multipage/parsing.html#parse-errors)
defines a number of standard parse error codes. These error codes only cover
the "tokenization" stage of parsing HTML. The parse errors in the
"tree construction" stage do not have standardized error codes (yet).

As a convenience to Nokogumbo users, the defined error codes are available
via the
[`Nokogiri::XML::SyntaxError#str1`](https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SyntaxError#str1-instance_method)
method.

```ruby
require 'nokogumbo'
doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
doc.errors.each do |err|
  puts("#{err.line}:#{err.column}: #{err.str1}")
end
```

This prints the following.
```
1:1: generic-parser
1:1: non-void-html-element-start-tag-with-trailing-solidus
1:17: end-tag-with-trailing-solidus
1:17: end-tag-with-attributes
```

Note that the first error is `generic-parser` because it's an error from the
tree construction stage and doesn't have a standardized error code.

For the purposes of semantic versioning, the error messages, error locations,
and error codes are not part of Nokogumbo's public API. That is, these are
subject to change without Nokogumbo's major version number changing. These may
be stabilized in the future.

### Maximum tree depth
The maximum depth of the DOM tree parsed by the various parsing methods is
configurable by the `:max_tree_depth` option. If the depth of the tree would
exceed this limit, then an
[ArgumentError](https://ruby-doc.org/core-2.5.0/ArgumentError.html) is thrown.

This limit (which defaults to `Nokogumbo::DEFAULT_MAX_TREE_DEPTH = 400`) can
be removed by giving the option `max_tree_depth: -1`.

``` ruby
html = '<!DOCTYPE html>' + '<div>' * 1000
doc = Nokogiri.HTML5(html)
# raises ArgumentError: Document tree depth limit exceeded
doc = Nokogiri.HTML5(html, max_tree_depth: -1)
```

## HTML Serialization

After parsing HTML, it may be serialized using any of the Nokogiri
[serialization
methods](https://www.rubydoc.info/gems/nokogiri/Nokogiri/XML/Node). In
particular, `#serialize`, `#to_html`, and `#to_s` will serialize a given node
and its children. (This is the equivalent of JavaScript's
`Element.outerHTML`.) Similarly, `#inner_html` will serialize the children of
a given node. (This is the equivalent of JavaScript's `Element.innerHTML`.)

``` ruby
doc = Nokogiri::HTML5("<!DOCTYPE html><span>Hello world!</span>")
puts doc.serialize
# Prints: <!DOCTYPE html><html><head></head><body><span>Hello world!</span></body></html>
```

Due to quirks in how HTML is parsed and serialized, it's possible for a DOM
tree to be serialized and then re-parsed, resulting in a different DOM.
Mostly, this happens with DOMs produced from invalid HTML. Unfortunately, even
valid HTML may not survive serialization and re-parsing.

In particular, a newline at the start of `pre`, `listing`, and `textarea`
elements is ignored by the parser.

``` ruby
doc = Nokogiri::HTML5(<<-EOF)
<!DOCTYPE html>
<pre>
Content</pre>
EOF
puts doc.at('/html/body/pre').serialize
# Prints: <pre>Content</pre>
```

In this case, the original HTML is semantically equivalent to the serialized
version. If the `pre`, `listing`, or `textarea` content starts with two
newlines, the first newline will be stripped on the first parse and the second
newline will be stripped on the second, leading to semantically different
DOMs. Passing the parameter `preserve_newline: true` will cause two or more
newlines to be preserved. (A single leading newline will still be removed.)

``` ruby
doc = Nokogiri::HTML5(<<-EOF)
<!DOCTYPE html>
<listing>

Content</listing>
EOF
puts doc.at('/html/body/listing').serialize(preserve_newline: true)
# Prints: <listing>
#
# Content</listing>
```

## Encodings
Nokogumbo always parses HTML using
[UTF-8](https://en.wikipedia.org/wiki/UTF-8); however, the encoding of the
input can be explicitly selected via the optional `encoding` parameter. This
is most useful when the input comes not from a string but from an IO object.

When serializing a document or node, the encoding of the output string can be
specified via the `:encoding` options. Characters that cannot be encoded in
the selected encoding will be encoded as [HTML numeric
entities](https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references).

``` ruby
frag = Nokogiri::HTML5.fragment('<span>아는 길도 물어가라</span>')
html = frag.serialize(encoding: 'US-ASCII')
puts html
# Prints: <span>&#xc544;&#xb294; &#xae38;&#xb3c4; &#xbb3c;&#xc5b4;&#xac00;&#xb77c;</span>
frag = Nokogiri::HTML5.fragment(html)
puts frag.serialize
# Prints: <span>아는 길도 물어가라</span>
```

(There's a [bug](https://bugs.ruby-lang.org/issues/15033) in all current
versions of Ruby that can cause the entity encoding to fail. Of the mandated
supported encodings for HTML, the only encoding I'm aware of that has this bug
is `'ISO-2022-JP'`. I recommend avoiding this encoding.)

## Examples
```ruby
require 'nokogumbo'
puts Nokogiri::HTML5.get('http://nokogiri.org').search('ol li')[2].text
```

## Notes

* The `Nokogiri::HTML5.fragment` function takes a string and parses it
  as a HTML5 document.  The `<html>`, `<head>`, and `<body>` elements are
  removed from this document, and any children of these elements that remain
  are returned as a `Nokogiri::HTML::DocumentFragment`.
* The `Nokogiri::HTML5.parse` function takes a string and passes it to the
<code>gumbo_parse_with_options</code> method, using the default options.
The resulting Gumbo parse tree is then walked.
  * If the necessary Nokogiri and [libxml2](http://xmlsoft.org/html/) headers
    can be found at installation time then an
    [xmlDoc](http://xmlsoft.org/html/libxml-tree.html#xmlDoc) tree is produced
    and a single Nokogiri Ruby object is constructed to wrap the xmlDoc
    structure.  Nokogiri only produces Ruby objects as necessary, so all
    searching is done using the underlying libxml2 libraries.
  * If the necessary headers are not present at installation time, then
    Nokogiri Ruby objects are created for each Gumbo node.  Other than
    memory usage and CPU time, the results should be equivalent.

* The `Nokogiri::HTML5.get` function takes care of following redirects,
https, and determining the character encoding of the result, based on the
rules defined in the HTML5 specification for doing so.

* Instead of uppercase element names, lowercase element names are produced.

* Instead of returning `unknown` as the element name for unknown tags, the
original tag name is returned verbatim.

# Flavors of Nokogumbo
Nokogumbo uses libxml2, the XML library underlying Nokogiri, to speed up
parsing. If the libxml2 headers are not available, then Nokogumbo resorts to
using Nokogiri's Ruby API to construct the DOM tree.

Nokogiri can be configured to either use the system library version of libxml2
or use a bundled version. By default (as of Nokogiri version 1.8.4), Nokogiri
will use a bundled version.

To prevent differences between versions of libxml2, Nokogumbo will only use
libxml2 if the build process can find the exact same version used by Nokogiri.
This leads to three possibilities

1. Nokogiri is compiled with the bundled libxml2. In this case, Nokogumbo will
   (by default) use the same version of libxml2.
2. Nokogiri is compiled with the system libxml2. In this case, if the libxml2
   headers are available, then Nokogumbo will (by default) use the system
   version and headers.
3. Nokogiri is compiled with the system libxml2 but its headers aren't
   available at build time for Nokogumbo. In this case, Nokogumbo will use the
   slower Ruby API.

Using libxml2 can be required by passing `-- --with-libxml2` to `bundle exec
rake` or to `gem install`. Using libxml2 can be prohibited by instead passing
`-- --without-libxml2`.

Functionally, the only difference between using libxml2 or not is in the
behavior of `Nokogiri::XML::Node#line`. If it is used, then `#line` will
return the line number of the corresponding node. Otherwise, it will return 0.

# Installation

    git clone https://github.com/rubys/nokogumbo.git
    cd nokogumbo
    bundle install
    rake gem
    gem install pkg/nokogumbo*.gem

# Related efforts

* [ruby-gumbo](https://github.com/nevir/ruby-gumbo#readme) -- a ruby binding
  for the Gumbo HTML5 parser.
* [lua-gumbo](https://gitlab.com/craigbarnes/lua-gumbo) -- a lua binding for
  the Gumbo HTML5 parser.
