module Icalendar

  class Event < Component
    required_property :dtstamp, Icalendar::Values::DateTime
    required_property :uid
    # dtstart only required if calendar's method is nil
    required_property :dtstart, Icalendar::Values::DateTime,
                      ->(event, dtstart) { !dtstart.nil? || !(event.parent.nil? || event.parent.ip_method.nil?) }

    optional_single_property :dtend, Icalendar::Values::DateTime
    optional_single_property :duration, Icalendar::Values::Duration
    mutually_exclusive_properties :dtend, :duration

    optional_single_property :ip_class
    optional_single_property :created, Icalendar::Values::DateTime
    optional_single_property :description
    optional_single_property :geo, Icalendar::Values::Float
    optional_single_property :last_modified, Icalendar::Values::DateTime
    optional_single_property :location
    optional_single_property :organizer, Icalendar::Values::CalAddress
    optional_single_property :priority, Icalendar::Values::Integer
    optional_single_property :sequence, Icalendar::Values::Integer
    optional_single_property :status
    optional_single_property :summary
    optional_single_property :transp
    optional_single_property :url, Icalendar::Values::Uri
    optional_single_property :recurrence_id, Icalendar::Values::DateTime

    optional_property :rrule, Icalendar::Values::Recur, true
    optional_property :attach, Icalendar::Values::Uri
    optional_property :attendee, Icalendar::Values::CalAddress
    optional_property :categories
    optional_property :comment
    optional_property :contact
    optional_property :exdate, Icalendar::Values::DateTime
    optional_property :request_status
    optional_property :related_to
    optional_property :resources
    optional_property :rdate, Icalendar::Values::DateTime

    component :alarm, false

    def initialize
      super 'event'
      self.dtstamp = Icalendar::Values::DateTime.new Time.now.utc, 'tzid' => 'UTC'
      self.uid = new_uid
    end

  end

end
