# Date Time, Date, Time


## Interface with core classes

ISO8601 classes provide a method `to_*` to convert to its core equivalent:

```ruby
ISO8601::DateTime#to_datetime # => #<DateTime: ...>
ISO8601::Date#to_date # => #<Date: ...>
ISO8601::Time#to_time # => #<Time: ...>
```

## Differences with core Date, Time and DateTime

### Reduced precision

Core `Date.parse` and `DateTime.parse` don't allow reduced precision. For
example:

```ruby
DateTime.parse('2014-05') # => ArgumentError: invalid date
```

But the standard covers this situation assuming any missing token as its lower
value:

```ruby
ISO8601::DateTime.new('2014-05').to_s # => "2014-05-01T00:00:00+00:00"
ISO8601::DateTime.new('2014').to_s # => "2014-01-01T00:00:00+00:00"
```

The same assumption happens in core classes with `.new`:

```ruby
DateTime.new(2014,5) # => #<DateTime: 2014-05-01T00:00:00+00:00 ((2456779j,0s,0n),+0s,2299161j)>
DateTime.new(2014) # => #<DateTime: 2014-01-01T00:00:00+00:00 ((2456659j,0s,0n),+0s,2299161j)>
```

### Unmatched precision

Unmatched precison is handled strongly. Notice the time fragment is lost in
`DateTime.parse` with no warning only if the loose precision is in the time
component.

```ruby
ISO8601::DateTime.new('2014-05-06T101112')  # => ISO8601::Errors::UnknownPattern
DateTime.parse('2014-05-06T101112')  # => #<DateTime: 2014-05-06T00:00:00+00:00 ((2456784j,0s,0n),+0s,2299161j)>

ISO8601::DateTime.new('20140506T10:11:12')  # => ISO8601::Errors::UnknownPattern
DateTime.parse('20140506T10:11:12')  # => #<DateTime: 2014-05-06T10:11:12+00:00 ((2456784j,0s,0n),+0s,2299161j)>
```

### Strong pattern matching

Week dates raise an error when two digit days provied instead of return monday:

```ruby
ISO8601::DateTime.new('2014-W15-02') # => ISO8601::Errors::UnknownPattern
DateTime.new('2014-W15-02')  # => #<Date: 2014-04-07 ((2456755j,0s,0n),+0s,2299161j)>
```


## Atomization

`DateTime#to_a` allows decomposing to an array of atoms:

```ruby
atoms = ISO8601::DateTime.new('2014-05-31T10:11:12Z').to_a # => [2014, 5, 31, 10, 11, 12, '+00:00']
dt = DateTime.new(*atoms)
```

## Sign

Ordinal dates keep the sign. `2014-001` is not the same as `-2014-001`.


## Fractional seconds precision

Fractional seconds for `ISO8601::DateTime` and `ISO8601::Time` are rounded to
one decimal.

```ruby
ISO8601::DateTime.new('2015-02-03T10:11:12.12').second #=> 12.1
ISO8601::Time.new('T10:11:12.16').second #=> 12.2
```
