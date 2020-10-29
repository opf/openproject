module Icalendar

  class Freebusy < Component

    required_property :dtstamp, Icalendar::Values::DateTime
    required_property :uid

    optional_single_property :contact
    optional_single_property :dtstart, Icalendar::Values::DateTime
    optional_single_property :dtend, Icalendar::Values::DateTime
    optional_single_property :organizer, Icalendar::Values::CalAddress
    optional_single_property :url, Icalendar::Values::Uri

    optional_property :attendee, Icalendar::Values::CalAddress
    optional_property :comment
    optional_property :freebusy, Icalendar::Values::Period
    optional_property :request_status

    def initialize
      super 'freebusy'
      self.dtstamp = Icalendar::Values::DateTime.new Time.now.utc, 'tzid' => 'UTC'
      self.uid = new_uid
    end

  end

end