# Duration

> Durations are a component of time intervals and define the amount of
> intervening time in a time interval. Source: [Wikipedia ISO8601](https://en.wikipedia.org/wiki/ISO_8601#Durations)

See [Time Interval](time-interval.md) for working with specific intervals of
time.

## Supported patterns

```
PnYnMnDTnHnMnS
PnW
```

`P<date>T<time>` will not be implemented.


## Usage

Some times using durations might be more convenient than using time intervals:

```ruby
duration = ISO8601::Duration.new('PT10H')
duration.to_seconds # => 36000.0
```

You can reuse the duration with a time interval:

```ruby
start_time = ISO8601::DateTime.new('2015-01-01T10:11:12Z')
time_interval = ISO8601::TimeInterval.from_duration(start_time, duration)
time_interval.size # => 36000.0
end_time = ISO8601::DateTime.new('2015-01-01T10:11:12Z')
time_interval = ISO8601::TimeInterval.from_duration(duration, end_time)
```

Or use an ad-hoc base:

```ruby
base = ISO8601::DateTime.new('2015-01-01T10:11:12Z')
duration = ISO8601::Duration.new('PT10H')
duration.to_seconds(base) # => 36000.0
```

**Warning**: When using durations without base, the result of `#to_seconds` is
an _average_.  See the atoms' implementation for details.


# Operate with durations

The `ISO8601::Duration` has the concept of sign to be able to represent negative
values:

```ruby
(ISO8601::Duration.new('PT10S') - ISO8601::Duration.new('PT12S')).to_s  #=> '-PT2S'
(ISO8601::Duration.new('-PT10S') + ISO8601::Duration.new('PT12S')).to_s #=> 'PT2S'
```

You can also inspect a duration by atom:

```
duration = ISO8601::Duration.new('P2Y1MT2H')
duration.years   # => #<ISO8601::Years ... @atom=2.0>
duration.months  # => #<ISO8601::Months ... @atom=1.0>
duration.days    # => #<ISO8601::Days ... @atom=0>
duration.hours   # => #<ISO8601::Hours ... @atom=2.0>
duration.minutes # => #<ISO8601::Hours ... @atom=0.0>
duration.seconds # => #<ISO8601::Hours ... @atom=0.0>
```

Or get back the pattern:

```ruby
duration.to_s # => 'P2Y1MT2H'
```
