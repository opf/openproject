require 'icalendar/logger'

module Icalendar

  MAX_LINE_LENGTH = 75

  def self.logger
    @logger ||= Icalendar::Logger.new(STDERR)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.parse(source, single = false)
    warn "**** DEPRECATION WARNING ****\nIcalendar.parse will be removed in 3.0. Please switch to Icalendar::Calendar.parse."
    calendars = Parser.new(source).parse
    single ? calendars.first : calendars
  end

end

require 'icalendar/has_properties'
require 'icalendar/has_components'
require 'icalendar/marshable'
require 'icalendar/component'
require 'icalendar/value'
require 'icalendar/alarm'
require 'icalendar/event'
require 'icalendar/todo'
require 'icalendar/journal'
require 'icalendar/freebusy'
require 'icalendar/timezone'
require 'icalendar/calendar'
require 'icalendar/parser'
