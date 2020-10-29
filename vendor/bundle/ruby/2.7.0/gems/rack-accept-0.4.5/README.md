# Rack::Accept

**Rack::Accept** is a suite of tools for Ruby/Rack applications that eases the
complexity of building and interpreting the Accept* family of [HTTP request headers][rfc].

Some features of the library are:

  * Strict adherence to [RFC 2616][rfc], specifically [section 14][rfc-sec14]
  * Full support for the [Accept][rfc-sec14-1], [Accept-Charset][rfc-sec14-2],
    [Accept-Encoding][rfc-sec14-3], and [Accept-Language][rfc-sec14-4] HTTP
    request headers
  * May be used as [Rack][rack] middleware or standalone
  * A comprehensive [test suite][test] that covers many edge cases

[rfc]: http://www.w3.org/Protocols/rfc2616/rfc2616.html
[rfc-sec14]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
[rfc-sec14-1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
[rfc-sec14-2]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.2
[rfc-sec14-3]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
[rfc-sec14-4]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
[rack]: http://rack.rubyforge.org/
[test]: http://github.com/mjijackson/rack-accept/tree/master/test/

## Installation

**Using [RubyGems](http://rubygems.org/):**

    $ sudo gem install rack-accept

**From a local copy:**

    $ git clone git://github.com/mjijackson/rack-accept.git
    $ cd rack-accept
    $ rake package && sudo rake install

## Usage

**Rack::Accept** implements the Rack middleware interface and may be used with any
Rack-based application. Simply insert the `Rack::Accept` module in your Rack
middleware pipeline and access the `Rack::Accept::Request` object in the
`rack-accept.request` environment key, as in the following example.

```ruby
require 'rack/accept'

use Rack::Accept

app = lambda do |env|
  accept = env['rack-accept.request']
  response = Rack::Response.new

  if accept.media_type?('text/html')
    response['Content-Type'] = 'text/html'
    response.write "<p>Hello. You accept text/html!</p>"
  else
    response['Content-Type'] = 'text/plain'
    response.write "Apparently you don't accept text/html. Too bad."
  end

  response.finish
end

run app
```

**Rack::Accept** can also construct automatic [406][406] responses if you set up
the types of media, character sets, encoding, or languages your server is able
to serve ahead of time. If you pass a configuration block to your `use`
statement it will yield the `Rack::Accept::Context` object that is used for that
invocation.

[406]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.7

```ruby
require 'rack/accept'

use(Rack::Accept) do |context|
  # We only ever serve content in English or Japanese from this site, so if
  # the user doesn't accept either of these we will respond with a 406.
  context.languages = %w< en jp >
end

app = ...

run app
```

**Note:** _You should think carefully before using Rack::Accept in this way.
Many user agents are careless about the types of Accept headers they send, and
depend on apps not being too picky. Instead of automatically sending a 406, you
should probably only send one when absolutely necessary._

Additionally, **Rack::Accept** may be used outside of a Rack context to provide
any Ruby app the ability to construct and interpret Accept headers.

```ruby
require 'rack/accept'

mtype = Rack::Accept::MediaType.new
mtype.qvalues = { 'text/html' => 1, 'text/*' => 0.8, '*/*' => 0.5 }
mtype.to_s # => "Accept: text/html, text/*;q=0.8, */*;q=0.5"

cset = Rack::Accept::Charset.new('unicode-1-1, iso-8859-5;q=0.8')
cset.best_of(%w< iso-8859-5 unicode-1-1 >)  # => "unicode-1-1"
cset.accept?('iso-8859-1')                  # => true
```

The very last line in this example may look like a mistake to someone not
familiar with the intricacies of [the spec][rfc-sec14-3], but it's actually
correct. It just puts emphasis on the convenience of using this library so you
don't have to worry about these kinds of details.

## Four-letter Words

  - Spec: [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html][rfc-sec14]
  - Code: [http://github.com/mjijackson/rack-accept][code]
  - Bugs: [http://github.com/mjijackson/rack-accept/issues][bugs]
  - Docs: [http://mjijackson.github.com/rack-accept][docs]

[code]: http://github.com/mjijackson/rack-accept
[bugs]: http://github.com/mjijackson/rack-accept/issues
[docs]: http://mjijackson.github.com/rack-accept

## License

Copyright 2012 Michael Jackson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.
