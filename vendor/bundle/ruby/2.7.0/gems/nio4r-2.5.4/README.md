# ![nio4r](https://raw.github.com/socketry/nio4r/master/logo.png)

[![Gem Version](https://badge.fury.io/rb/nio4r.svg)](http://rubygems.org/gems/nio4r)
[![Build Status](https://github.com/socketry/nio4r/workflows/nio4r/badge.svg?branch=master&event=push)](https://github.com/socketry/nio4r/actions?query=workflow:nio4r)
[![Code Climate](https://codeclimate.com/github/socketry/nio4r.svg)](https://codeclimate.com/github/socketry/nio4r)
[![Coverage Status](https://coveralls.io/repos/socketry/nio4r/badge.svg?branch=master)](https://coveralls.io/r/socketry/nio4r)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/gems/nio4r/2.2.0)

**New I/O for Ruby (nio4r)**: cross-platform asynchronous I/O primitives for
scalable network clients and servers. Modeled after the Java NIO API, but
simplified for ease-of-use.

**nio4r** provides an abstract, cross-platform stateful I/O selector API for Ruby.
I/O selectors are the heart of "reactor"-based event loops, and monitor
multiple I/O objects for various types of readiness, e.g. ready for reading or
writing.

## Projects using nio4r

* [ActionCable]: Rails 5 WebSocket protocol, uses nio4r for a WebSocket server
* [Celluloid]: Actor-based concurrency framework, uses nio4r for async I/O
* [Async]: Asynchronous I/O framework for Ruby
* [Puma]: Ruby/Rack web server built for concurrency

[ActionCable]: https://rubygems.org/gems/actioncable
[Celluloid]: https://github.com/celluloid/celluloid-io
[Async]: https://github.com/socketry/async
[Puma]: https://github.com/puma/puma

## Goals

* Expose high-level interfaces for stateful IO selectors
* Keep the API small to maximize both portability and performance across many
  different OSes and Ruby VMs
* Provide inherently thread-safe facilities for working with IO objects

## Supported platforms

* Ruby 2.4
* Ruby 2.5
* Ruby 2.6
* Ruby 2.7
* [JRuby](https://github.com/jruby/jruby)
* [TruffleRuby](https://github.com/oracle/truffleruby)

## Supported backends

* **libev**: MRI C extension targeting multiple native IO selector APIs (e.g epoll, kqueue)
* **Java NIO**: JRuby extension which wraps the Java NIO subsystem
* **Pure Ruby**: `Kernel.select`-based backend that should work on any Ruby interpreter

## Documentation

[Please see the nio4r wiki](https://github.com/socketry/nio4r/wiki)
for more detailed documentation and usage notes:

* [Getting Started]: Introduction to nio4r's components
* [Selectors]: monitor multiple `IO` objects for readiness events
* [Monitors]: control interests and inspect readiness for specific `IO` objects
* [Byte Buffers]: fixed-size native buffers for high-performance I/O

[Getting Started]: https://github.com/socketry/nio4r/wiki/Getting-Started
[Selectors]: https://github.com/socketry/nio4r/wiki/Selectors
[Monitors]: https://github.com/socketry/nio4r/wiki/Monitors
[Byte Buffers]: https://github.com/socketry/nio4r/wiki/Byte-Buffers

See also:

* [YARD API documentation](http://www.rubydoc.info/gems/nio4r/frames)

## Non-goals

**nio4r** is not a full-featured event framework like [EventMachine] or [Cool.io].
Instead, nio4r is the sort of thing you might write a library like that on
top of. nio4r provides a minimal API such that individual Ruby implementers
may choose to produce optimized versions for their platform, without having
to maintain a large codebase.

[EventMachine]: https://github.com/eventmachine/eventmachine
[Cool.io]: https://coolio.github.io/

## Releases

### CRuby

```
rake clean
rake release
```

### JRuby

You might need to delete `Gemfile.lock` before trying to `bundle install`.

```
rake clean
rake compile
rake release
```

## License

Released under the MIT license.

Copyright, 2019, by Tony Arcieri.  
Copyright, 2019, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

### libev

Released under the BSD license. See [ext/libev/LICENSE] for details.

Copyright, 2007-2019, by Marc Alexander Lehmann.

[ext/libev/LICENSE]: https://github.com/socketry/nio4r/blob/master/ext/libev/LICENSE
