# escape_utils

Being as though we're all html escaping everything these days, why not make it faster?

For character encoding in 1.9, the output string's encoding is copied from the input string.

It has monkey-patches for Rack::Utils, CGI, URI, ERB::Util and Haml and ActionView so you can drop this in and have your app start escaping fast as balls in no time

It supports HTML, URL, URI and Javascript escaping/unescaping.

## Installing

Compatible with Ruby 1.9.3+

``` sh
gem install escape_utils
```

## Warning: UTF-8 only

escape_utils assumes all input is encoded as valid UTF-8. If you are dealing with other encodings do your best to transcode the string into a UTF-8 byte stream before handing it to escape_utils.


``` ruby
utf8_string = non_utf8_string.encode('UTF-8')
```

## Usage

### HTML

#### Escaping

``` ruby
html = `curl -s http://maps.google.com`
escaped_html = EscapeUtils.escape_html(html)
```

By default escape_utils will escape `/` characters with `&#47;`, but you can disable that by setting `EscapeUtils.html_secure = false`
or per-call by passing `false` as the second parameter to `escape_html` like `EscapeUtils.escape_html(html, false)`

For more information check out: http://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet#RULE_.231_-_HTML_Escape_Before_Inserting_Untrusted_Data_into_HTML_Element_Content

#### Unescaping

``` ruby
html = `curl -s http://maps.google.com`
escaped_html = EscapeUtils.escape_html(html)
html = EscapeUtils.unescape_html(escaped_html)
```

#### Monkey Patches

``` ruby
require 'escape_utils/html/rack' # to patch Rack::Utils
require 'escape_utils/html/erb' # to patch ERB::Util
require 'escape_utils/html/cgi' # to patch CGI
require 'escape_utils/html/haml' # to patch Haml::Helpers
```

### URL

Use (un)escape_uri to get RFC-compliant escaping (like PHP rawurlencode).

Use (un)escape_url to get CGI escaping (where space is +).

#### Escaping

``` ruby
url = "https://www.yourmom.com/cgi-bin/session.cgi?sess_args=mcEA~!!#*YH*>@!U"
escaped_url = EscapeUtils.escape_url(url)
```

#### Unescaping

``` ruby
url = "https://www.yourmom.com/cgi-bin/session.cgi?sess_args=mcEA~!!#*YH*>@!U"
escaped_url = EscapeUtils.escape_url(url)
EscapeUtils.unescape_url(escaped_url) == url # => true
```

#### Monkey Patches

``` ruby
require 'escape_utils/url/cgi' # to patch CGI
require 'escape_utils/url/erb' # to patch ERB::Util
require 'escape_utils/url/rack' # to patch Rack::Utils
require 'escape_utils/url/uri' # to patch URI
```

### Javascript

#### Escaping

``` ruby
javascript = `curl -s http://code.jquery.com/jquery-1.4.2.js`
escaped_javascript = EscapeUtils.escape_javascript(javascript)
```

#### Unescaping

``` ruby
javascript = `curl -s http://code.jquery.com/jquery-1.4.2.js`
escaped_javascript = EscapeUtils.escape_javascript(javascript)
EscapeUtils.unescape_javascript(escaped_javascript) == javascript # => true
```

#### Monkey Patches

``` ruby
require 'escape_utils/javascript/action_view' # to patch ActionView::Helpers::JavaScriptHelper
```

## Benchmarks

In my testing, escaping html is around 10-30x faster than the pure ruby implementations in wide use today.
While unescaping html is around 40-100x faster than CGI.unescapeHTML which is also pure ruby.
Escaping Javascript is around 16-30x faster.

This output is from my laptop using the benchmark scripts in the benchmarks folder.

### HTML

#### Escaping

```
Rack::Utils.escape_html
 9.650000   0.090000   9.740000 (  9.750756)
Haml::Helpers.html_escape
 9.310000   0.110000   9.420000 (  9.417317)
ERB::Util.html_escape
 5.330000   0.390000   5.720000 (  5.748394)
CGI.escapeHTML
 5.370000   0.380000   5.750000 (  5.791344)
FasterHTMLEscape.html_escape
 0.520000   0.010000   0.530000 (  0.539485)
fast_xs_extra#fast_xs_html
 0.310000   0.030000   0.340000 (  0.336734)
EscapeUtils.escape_html
 0.200000   0.050000   0.250000 (  0.258839)
```

#### Unescaping

```
CGI.unescapeHTML
 16.520000   0.080000  16.600000 ( 16.853888)
EscapeUtils.unescape_html
 0.120000   0.040000   0.160000  (  0.162696)
```

### Javascript

#### Escaping

```
ActionView::Helpers::JavaScriptHelper#escape_javascript
 3.810000   0.100000   3.910000 (  3.925557)
EscapeUtils.escape_javascript
 0.200000   0.040000   0.240000 (  0.236692)
```

#### Unescaping

I didn't look that hard, but I'm not aware of another ruby library that does Javascript unescaping to benchmark against. Anyone know of any?

### URL

#### Escaping

```
ERB::Util.url_encode
 0.520000   0.010000   0.530000 (  0.529277)
Rack::Utils.escape
 0.460000   0.010000   0.470000 (  0.466962)
CGI.escape
 0.440000   0.000000   0.440000 (  0.443017)
URLEscape#escape
 0.040000   0.000000   0.040000 (  0.045661)
fast_xs_extra#fast_xs_url
 0.010000   0.000000   0.010000 (  0.015429)
EscapeUtils.escape_url
 0.010000   0.000000   0.010000 (  0.010843)
```

#### Unescaping

```
Rack::Utils.unescape
 0.250000   0.010000   0.260000 (  0.257558)
CGI.unescape
 0.250000   0.000000   0.250000 (  0.257837)
URLEscape#unescape
 0.040000   0.000000   0.040000 (  0.031548)
fast_xs_extra#fast_uxs_cgi
 0.010000   0.000000   0.010000 (  0.006062)
EscapeUtils.unescape_url
 0.000000   0.000000   0.000000 (  0.005679)
```
