module Icalendar

  class Journal < Component

    required_property :dtstamp, Icalendar::Values::DateTime
    required_property :uid

    optional_single_property :ip_class
    optional_single_property :created, Icalendar::Values::DateTime
    optional_single_property :dtstart, Icalendar::Values::DateTime
    optional_single_property :last_modified, Icalendar::Values::DateTime
    optional_single_property :organizer, Icalendar::Values::CalAddress
    optional_single_property :recurrence_id, Icalendar::Values::DateTime
    optional_single_property :sequence, Icalendar::Values::Integer
    optional_single_property :status
    optional_single_property :summary
    optional_single_property :url, Icalendar::Values::Uri

    optional_property :rrule, Icalendar::Values::Recur, true
    optional_property :attach, Icalendar::Values::Uri
    optional_property :attendee, Icalendar::Values::CalAddress
    optional_property :categories
    optional_property :comment
    optional_property :contact
    optional_property :description
    optional_property :exdate, Icalendar::Values::DateTime
    optional_property :request_status
    optional_property :related_to
    optional_property :rdate, Icalendar::Values::DateTime

    def initialize
      super 'journal'
      self.dtstamp = Icalendar::Values::DateTime.new Time.now.utc, 'tzid' => 'UTC'
      self.uid = new_uid
    end

  end

end