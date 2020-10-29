ruby-duration
=============

Duration is an immutable type that represents some amount of time with accuracy in seconds.

A lot of the code and inspirations is borrowed from [duration](http://rubyforge.org/projects/duration)
lib, which is a **mutable** Duration type with lot more features.



Features
--------

  * Representation of time in weeks, days, hours, minutes and seconds.
  * Construtor can receive the amount of time in seconds or a Hash with unit and amount of time.
  * Format method to display the time with i18n support.
  * Mongoid serialization support. Use `require 'duration/mongoid'`.
  * Tested on mri 1.9.3 and jruby. Kudos to rvm!


Show me the code
----------------

### constructor

    Duration.new(100) => #<Duration: minutes=1, seconds=40, total=100>
    Duration.new(:hours => 5, :minutes => 70) => #<Duration: hours=6, minutes=10, total=22200>

### format

    Duration.new(:weeks => 3, :days => 1).format("%w %~w and %d %~d") => "3 weeks and 1 day"
    Duration.new(:weeks => 1, :days => 20).format("%w %~w and %d %~d") => "3 weeks and 6 days"

### [iso 8601](http://en.wikipedia.org/wiki/ISO_8601#Durations)

    Duration.new(:weeks => 1, :days => 20).iso8601 => "P3W6DT0H0M0S"

### Mongoid support
The current version of this gem supports Mongoid >= [3.0.0](https://github.com/mongoid/mongoid).
For lower Mongoid versions try:
 * < 3.0.0 tag [v2.1.4](https://github.com/peleteiro/ruby-duration/tree/v2.1.4)
 * < 2.1.0 tag [v1.0.0](https://github.com/peleteiro/ruby-duration/tree/v1.0.0)

```
    require 'duration/mongoid'

    class MyModel
      include Mongoid::Document
      field :duration, type => Duration
    end
```

### Dependencies
The current version of this gem runs only on Ruby Versions >= 1.9.3.
If you are running a older version of Ruby try:
* tag [v2.1.4](https://github.com/peleteiro/ruby-duration/tree/v2.1.4)


Note on Patches/Pull Requests
-----------------------------

  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it. This is important so I don't break it in a
    future version unintentionally.
  * Commit, do not mess with rakefile, version, or history.
    (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
  * Send me a pull request. Bonus points for topic branches.


License
---------
Copyright (c) 2010 Jose Peleteiro

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
