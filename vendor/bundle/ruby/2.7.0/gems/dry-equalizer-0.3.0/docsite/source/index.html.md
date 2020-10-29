---
title: Introduction &amp; Usage
description: Simple mixin providing equality, equivalence and inspection methods
layout: gem-single
order: 5
type: gem
name: dry-equalizer
---

`dry-equalizer` is a simple mixin that can be used to add instance variable based equality, equivalence and inspection methods to your objects.

### Usage

```ruby
require 'dry-equalizer'

class GeoLocation
  include Dry::Equalizer(:latitude, :longitude)

  attr_reader :latitude, :longitude

  def initialize(latitude, longitude)
    @latitude, @longitude = latitude, longitude
  end
end

point_a = GeoLocation.new(1, 2)
point_b = GeoLocation.new(1, 2)
point_c = GeoLocation.new(2, 2)

point_a.inspect    # => "#<GeoLocation latitude=1 longitude=2>"

point_a == point_b           # => true
point_a.hash == point_b.hash # => true
point_a.eql?(point_b)        # => true
point_a.equal?(point_b)      # => false

point_a == point_c           # => false
point_a.hash == point_c.hash # => false
point_a.eql?(point_c)        # => false
point_a.equal?(point_c)      # => false
```

### Configuration options

#### `inspect`

Use `inspect` option to skip `#inspect` method overloading:

```ruby
class Foo
  include Dry::Equalizer(:a, inspect: false)

  attr_reader :a, :b

  def initialize(a, b)
    @a, @b = a, b
  end
end

Foo.new(1, 2).inspect
# => "#<Foo:0x00007fbc9c0487f0 @a=1, @b=2>"
```

#### `immutable`

For objects that are immutable it doesn't make sense to calculate `#hash` every time it's called. To memoize hash use `immutable` option:

```ruby
class ImmutableHash
  include Dry::Equalizer(:foo, :bar, immutable: true)

  attr_accessor :foo, :bar

  def initialize(foo, bar)
    @foo, @bar = foo, bar
  end
end

obj = ImmutableHash.new('foo', 'bar')
old_hash = obj.hash
obj.foo = 'changed'
old_hash == obj.hash
# => true
```

