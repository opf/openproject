# Time Interval

> A time interval is the intervening time between two time points.
Source: [Wikipedia ISO8601](https://en.wikipedia.org/wiki/ISO_8601#Time_intervals)

This library implements the Time Interval type via [`ISO8601::TimeInterval`](../lib/iso8601/time_interval.rb)
with the following constructors:

* `TimeInterval.new(String)` (or `TimeInterval.parse(String)`)
* `TimeInterval.from_duration(Duration, Hash<DateTime>)`
* `TimeInterval.from_datetime(DateTime, DateTime)`


## Supported patterns

```
<start>/<end>
<start>/<duration>
<duration>/<end>
```

Where `<start>` and `<end>` are points in time and `<duration>` is an amount of
time.

The pattern `<duration>` is not implemented; instead, you can use
[`TimeInterval.from_duration`](../lib/iso8601/time_interval.rb#L70).


## Usage

### `<start>/<end>`

The resulting time interval will have a starting point based on the provided
`<start>` pattern and an ending point based on the provided `<end>` pattern.

```ruby
ti = ISO8601::TimeInterval.parse('2015-12-12T19:53:00Z/2015-12-13T19:53:00Z')
ti.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti.size             # => 86_400.0
```

### `<start>/<duration>`

The resulting time interval will have a starting point based on the provided
`<start>` pattern and an ending point result of `<start> + <duration>`.

```ruby
ti = ISO8601::TimeInterval.parse('2015-12-12T19:53:00Z/P1D')
ti.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti.size             # => 86_400.0
```

### `<duration>/<end>`

The resulting time interval will have a starting point result of
`<end> - <duration>` and an ending point based on the provided `<end>` pattern.

```ruby
ti = ISO8601::TimeInterval.parse('P1D/2015-12-13T19:53:00Z')
ti.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti.size             # => 86_400.0
```


### `TimeInterval.from_duration`

```ruby
duration = ISO8601::Duration.new('P1D`)
start_time = ISO8601::DateTime.new('2015-12-12T19:53:00Z')
ti = ISO8601::TimeInterval.from_duration(start_time, duration)
ti.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti.size             # => 86_400.0


end_time = ISO8601::DateTime.new('2015-12-13T19:53:00Z')
ti2 = ISO8601::TimeInterval.from_duration(duration, end_time)
ti2.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti2.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti2.size             # => 86_400.0
```

### `TimeInterval.from_datetime`

This constructor is an alternative way to `<start>/<end>` via Ruby objects.

```ruby
start_time = ISO8601::DateTime.new('2015-12-12T19:53:00Z')
end_time = ISO8601::DateTime.new('2015-12-13T19:53:00Z')
ti2 = ISO8601::TimeInterval.from_duration(start_time, end_time)
ti2.start_time.to_s  # => '2015-12-12T19:53:00Z'
ti2.end_time.to_s    # => '2015-12-13T19:53:00Z'
ti2.size             # => 86_400.0
```

## Operate with time intervals

`TimeInterval` is `Comparable`, so you can use the usual `<`, `>`, `<=`, `>=`,
`==` to compare against another `TimeInterval`.  Is equivalent to get the
amount of seconds via `#to_f` and compare the resulting numbers.

A time interval can be viewed as an ordered set of datetime elements:

* `#empty?` checks if an interval is empty.
* `#include?` checks if a `DateTime` is part of the time interval.
* `#intersect?` checks if two time intervals overlap.
* `#intersection` returns the intersected time interval if the two intervals intersect.
* `#disjoint?` checks if two time intervals don't intersect.
* `#subset?` checks if a time interval is included in another one.
* `#superset?` checks if a time interval is included in another one.
* `#first` is the lower bound.
* `#last` is the upper bound.
* `#size` is the total amount of seconds.


You can convert a time interval into a string with `#to_s` or into a float via
`#to_f`.
