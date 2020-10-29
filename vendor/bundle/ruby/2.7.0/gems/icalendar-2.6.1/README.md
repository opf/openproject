iCalendar -- Internet calendaring, Ruby style
===

[![Build Status](https://travis-ci.org/icalendar/icalendar.svg?branch=master)](https://travis-ci.org/icalendar/icalendar)
[![Code Climate](https://codeclimate.com/github/icalendar/icalendar.png)](https://codeclimate.com/github/icalendar/icalendar)

<http://github.com/icalendar/icalendar>

### Upgrade from 1.x ###

Better documentation is still to come, but in the meantime the changes needed to move from 1.x to 2.0 are summarized by the [diff needed to update the README](https://github.com/icalendar/icalendar/commit/bc3701e004c915a250054030a9375d1e7618857f)

DESCRIPTION
---

iCalendar is a Ruby library for dealing with iCalendar files in the
iCalendar format defined by [RFC-5545](http://tools.ietf.org/html/rfc5545).

EXAMPLES
---

### Creating calendars and events ###

```ruby
require 'icalendar'

# Create a calendar with an event (standard method)
cal = Icalendar::Calendar.new
cal.event do |e|
  e.dtstart     = Icalendar::Values::Date.new('20050428')
  e.dtend       = Icalendar::Values::Date.new('20050429')
  e.summary     = "Meeting with the man."
  e.description = "Have a long lunch meeting and decide nothing..."
  e.ip_class    = "PRIVATE"
end

cal.publish
```

#### Or you can make events like this ####

```ruby
event = Icalendar::Event.new
event.dtstart = DateTime.civil(2006, 6, 23, 8, 30)
event.summary = "A great event!"
cal.add_event(event)

event2 = cal.event  # This automatically adds the event to the calendar
event2.dtstart = DateTime.civil(2006, 6, 24, 8, 30)
event2.summary = "Another great event!"
```

#### Support for property parameters ####

```ruby
params = {"altrep" => "http://my.language.net", "language" => "SPANISH"}

event = cal.event do |e|
  e.dtstart = Icalendar::Values::Date.new('20050428')
  e.dtend   = Icalendar::Values::Date.new('20050429')
  e.summary = Icalendar::Values::Text.new "This is a summary with params.", params
end
event.summary.ical_params #=> {'altrep' => 'http://my.language.net', 'language' => 'SPANISH'}

# or

event = cal.event do |e|
  e.dtstart = Icalendar::Values::Date.new('20050428')
  e.dtend   = Icalendar::Values::Date.new('20050429')
  e.summary = "This is a summary with params."
  e.summary.ical_params = params
end
event.summary.ical_params #=> {'altrep' => 'http://my.language.net', 'language' => 'SPANISH'}
```

#### Support for Dates or DateTimes

Sometimes we don't care if an event's start or end are `Date` or `DateTime` objects. For this, we can use `DateOrDateTime.new(value)`. Calling `.call` on the returned `DateOrDateTime` will immediately return the underlying `Date` or `DateTime` object.

```ruby
event = cal.event do |e|
  e.dtstart = Icalendar::Values::DateOrDateTime.new('20140924')
  e.dtend   = Icalendar::Values::DateOrDateTime.new('20140925').call
  e.summary = 'This is an all-day event, because DateOrDateTime will return Dates'
end
```

#### Support for URLs

For clients that can parse and display a URL associated with an event, it's possible to assign one.

```ruby
event = cal.event do |e|
  e.url = 'https://example.com'
end
```

#### We can output the calendar as a string ####

    cal_string = cal.to_ical
    puts cal_string

ALARMS
---

### Within an event ###

```ruby
cal.event do |e|
  # ...other event properties
  e.alarm do |a|
    a.action          = "EMAIL"
    a.description     = "This is an event reminder" # email body (required)
    a.summary         = "Alarm notification"        # email subject (required)
    a.attendee        = %w(mailto:me@my-domain.com mailto:me-too@my-domain.com) # one or more email recipients (required)
    a.append_attendee "mailto:me-three@my-domain.com"
    a.trigger         = "-PT15M" # 15 minutes before
    a.append_attach   Icalendar::Values::Uri.new "ftp://host.com/novo-procs/felizano.exe", "fmttype" => "application/binary" # email attachments (optional)
  end

  e.alarm do |a|
    a.action  = "DISPLAY" # This line isn't necessary, it's the default
    a.summary = "Alarm notification"
    a.trigger = "-P1DT0H0M0S" # 1 day before
  end

  e.alarm do |a|
    a.action        = "AUDIO"
    a.trigger       = "-PT15M"
    a.append_attach "Basso"
  end
end
```

#### Output ####

    # BEGIN:VALARM
    # ACTION:EMAIL
    # ATTACH;FMTTYPE=application/binary:ftp://host.com/novo-procs/felizano.exe
    # TRIGGER:-PT15M
    # SUMMARY:Alarm notification
    # DESCRIPTION:This is an event reminder
    # ATTENDEE:mailto:me-too@my-domain.com
    # ATTENDEE:mailto:me-three@my-domain.com
    # END:VALARM
    #
    # BEGIN:VALARM
    # ACTION:DISPLAY
    # TRIGGER:-P1DT0H0M0S
    # SUMMARY:Alarm notification
    # END:VALARM
    #
    # BEGIN:VALARM
    # ACTION:AUDIO
    # ATTACH;VALUE=URI:Basso
    # TRIGGER:-PT15M
    # END:VALARM

#### Checking for an Alarm ####

Calling the `event.alarm` method will create an alarm if one doesn't exist. To check if an event has an alarm use the `has_alarm?` method.

```ruby
event.has_alarm?
# => false

event.alarm
# => #<Icalendar::Alarm ... >

event.has_alarm?
#=> true
```

TIMEZONES
---

```ruby
cal = Icalendar::Calendar.new
cal.timezone do |t|
  t.tzid = "America/Chicago"

  t.daylight do |d|
    d.tzoffsetfrom = "-0600"
    d.tzoffsetto   = "-0500"
    d.tzname       = "CDT"
    d.dtstart      = "19700308T020000"
    d.rrule        = "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
  end

  t.standard do |s|
    s.tzoffsetfrom = "-0500"
    s.tzoffsetto   = "-0600"
    s.tzname       = "CST"
    s.dtstart      = "19701101T020000"
    s.rrule        = "FREQ=YEARLY;BYMONTH=11;BYDAY=1SU"
  end
end
```

#### Output ####

    # BEGIN:VTIMEZONE
    # TZID:America/Chicago
    # BEGIN:DAYLIGHT
    # TZOFFSETFROM:-0600
    # TZOFFSETTO:-0500
    # TZNAME:CDT
    # DTSTART:19700308T020000
    # RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
    # END:DAYLIGHT
    # BEGIN:STANDARD
    # TZOFFSETFROM:-0500
    # TZOFFSETTO:-0600
    # TZNAME:CST
    # DTSTART:19701101T020000
    # RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
    # END:STANDARD
    # END:VTIMEZONE

iCalendar has some basic support for creating VTIMEZONE blocks from timezone information pulled from `tzinfo`.
You must require `tzinfo` support manually to take advantage.

iCalendar has been tested and works with `tzinfo` versions 0.3 and 1.x

#### Example ####

```ruby
require 'icalendar/tzinfo'

cal = Icalendar::Calendar.new

event_start = DateTime.new 2008, 12, 29, 8, 0, 0
event_end = DateTime.new 2008, 12, 29, 11, 0, 0

tzid = "America/Chicago"
tz = TZInfo::Timezone.get tzid
timezone = tz.ical_timezone event_start
cal.add_timezone timezone

cal.event do |e|
  e.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => tzid
  e.dtend   = Icalendar::Values::DateTime.new event_end, 'tzid' => tzid
  e.summary = "Meeting with the man."
  e.description = "Have a long lunch meeting and decide nothing..."
  e.organizer = "mailto:jsmith@example.com"
  e.organizer = Icalendar::Values::CalAddress.new("mailto:jsmith@example.com", cn: 'John Smith')
end
```


Parsing iCalendars
---

```ruby
# Open a file or pass a string to the parser
cal_file = File.open("single_event.ics")

# Parser returns an array of calendars because a single file
# can have multiple calendars.
cals = Icalendar::Calendar.parse(cal_file)
cal = cals.first

# Now you can access the cal object in just the same way I created it
event = cal.events.first

puts "start date-time: #{event.dtstart}"
puts "start date-time timezone: #{event.dtstart.ical_params['tzid']}"
puts "summary: #{event.summary}"
```

You can also create a `Parser` instance directly, this can be used to enable
strict parsing:

```ruby
# Sometimes you want to strongly verify only rfc-approved properties are
# used
strict_parser = Icalendar::Parser.new(cal_file, true)
cal = strict_parser.parse
```

Parsing Components (e.g. Events)
---

```ruby
# Open a file or pass a string to the parser
event_file = File.open("event.ics")

# Parser returns an array of events because a single file
# can have multiple events.
events = Icalendar::Event.parse(event_file)
event = events.first

puts "start date-time: #{event.dtstart}"
puts "start date-time timezone: #{event.dtstart.ical_params['tzid']}"
puts "summary: #{event.summary}"
```

Finders
---

Often times in web apps and other interactive applications you'll need to
lookup items in a calendar to make changes or get details.  Now you can find
everything by the unique id automatically associated with all components.

```ruby
cal = Calendar.new
10.times { cal.event } # Create 10 events with only default data.
some_event = cal.events[5] # Grab it from the array of events

# Use the uid as the key in your app
key = some_event.uid

# so later you can find it.
same_event = cal.find_event(key)
```

Examples
---

Check the unit tests for examples of most things you'll want to do, but please
send me example code or let me know what's missing.

Download
---

The latest release version of this library can be found at

* <http://rubygems.org/gems/icalendar>

Installation
---

It's all about rubygems:

    $ gem install icalendar

Testing
---

To run the tests:

    $ bundle install
    $ rake spec

License
---

This library is released under the same license as Ruby itself.


Support & Contributions
---

Please submit pull requests from a rebased topic branch and
include tests for all bugs and features.

Contributor Code of Conduct
---

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This Code of Conduct is adapted from the [Contributor Covenant](http://contributor-covenant.org), version 1.1.0, available at [http://contributor-covenant.org/version/1/1/0/](http://contributor-covenant.org/version/1/1/0/)
