Semantic
========
[![BuildStatus](https://travis-ci.org/jlindsey/semantic.svg?branch=master)](https://travis-ci.org/jlindsey/semantic)

A small Ruby utility class to aid in the storage, parsing, and comparison of SemVer-style Version strings.

See [the SemVer site](http://semver.org) for more details.

Usage
-----

This library exposes a single class – `Semantic::Version`. Simply pass in a valid SemVer string to
the initializer.

```ruby
require 'semantic'

version = Semantic::Version.new '1.6.5'
version.major             # => 1
version.minor             # => 6
version.patch             # => 5

newer_version = Semantic::Version.new '1.7.0'
version > newer_version   # => false
newer_version <=> version # => 1

complex_version = Semantic::Version.new '3.7.9-pre.1+revision.15723'
complex_version.pre       # => "pre.1"
complex_version.build     # => "revision.15623"

# semantic supports Pessimistic Operator
version.satisfies? '~> 1.5'    # => true
version.satisfies? '~> 1.6.0'  # => true

# incrementing version numbers
version = Semantic::Version.new('0.1.0')
new_version = version.increment!(:major)    # 1.1.0
new_version = version.increment!(:minor)    # 0.2.0
new_version = version.increment!(:patch)    # 0.1.1

new_version = verstion.major!               # 1.1.0
new_version = verstion.minor!               # 0.2.0
new_version = verstion.patch!               # 0.1.1
# (note: increment! & friends return a copy and leave the original unchanged)
```

There is also a set of core extensions as an optional require:

```ruby
require 'semantic'
require 'semantic/core_ext'

"1.8.7-pre.123".to_version
```

License
-------
Copyright (c) 2012 Josh Lindsey. See [LICENSE](LICENSE) for details.

