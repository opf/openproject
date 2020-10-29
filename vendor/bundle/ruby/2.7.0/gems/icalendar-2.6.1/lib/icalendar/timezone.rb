require 'ice_cube'

module Icalendar

  class Timezone < Component
    module TzProperties
      def self.included(base)
        base.class_eval do
          required_property :dtstart, Icalendar::Values::DateTime
          required_property :tzoffsetfrom, Icalendar::Values::UtcOffset
          required_property :tzoffsetto, Icalendar::Values::UtcOffset

          optional_property :rrule, Icalendar::Values::Recur, true
          optional_property :comment
          optional_property :rdate, Icalendar::Values::DateTime
          optional_property :tzname

          transient_variable :@cached_occurrences
          transient_variable :@occurrences
        end
      end

      def occurrences
        @occurrences ||= IceCube::Schedule.new(dtstart.to_time) do |s|
          rrule.each do |rule|
            s.add_recurrence_rule IceCube::Rule.from_ical(rule.value_ical)
          end
          rdate.each do |date|
            s.add_recurrence_time date.to_time
          end
        end.all_occurrences_enumerator
      end

      def previous_occurrence(from)
        from = IceCube::TimeUtil.match_zone(from, dtstart.to_time)

        @cached_occurrences ||= []
        while @cached_occurrences.empty? || @cached_occurrences.last <= from
          begin
            @cached_occurrences << occurrences.next
          rescue StopIteration
            break
          end
        end

        @cached_occurrences.reverse_each.find { |occurrence| occurrence < from }
      end
    end
    class Daylight < Component
      include Marshable
      include TzProperties

      def initialize
        super 'daylight', 'DAYLIGHT'
      end
    end
    class Standard < Component
      include Marshable
      include TzProperties

      def initialize
        super 'standard', 'STANDARD'
      end
    end


    required_property :tzid

    optional_single_property :last_modified, Icalendar::Values::DateTime
    optional_single_property :tzurl, Icalendar::Values::Uri

    component :daylight, false, Icalendar::Timezone::Daylight
    component :standard, false, Icalendar::Timezone::Standard

    def initialize
      super 'timezone'
    end

    def valid?(strict = false)
      daylights.empty? && standards.empty? and return false
      daylights.all? { |d| d.valid? strict } or return false
      standards.all? { |s| s.valid? strict } or return false
      super
    end

    def offset_for_local(local)
      standard = standard_for local
      daylight = daylight_for local

      if standard.nil? && daylight.nil?
        "+00:00"
      elsif daylight.nil?
        standard.last.tzoffsetto
      elsif standard.nil?
        daylight.last.tzoffsetto
      else
        sdst = standard.first
        ddst = daylight.first
        if sdst > ddst
          standard.last.tzoffsetto
        else
          daylight.last.tzoffsetto
        end
      end
    end

    def standard_for(local)
      possible = standards.map do |std|
        [std.previous_occurrence(local.to_time), std]
      end
      possible.sort_by(&:first).last
    end

    def daylight_for(local)
      possible = daylights.map do |day|
        [day.previous_occurrence(local.to_time), day]
      end
      possible.sort_by(&:first).last
    end
  end
end
