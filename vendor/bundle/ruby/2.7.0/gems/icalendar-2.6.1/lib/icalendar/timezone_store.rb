require 'delegate'
require 'icalendar/downcased_hash'

module Icalendar
  class TimezoneStore < ::SimpleDelegator

    def initialize
      super DowncasedHash.new({})
    end

    def self.instance
      warn "**** DEPRECATION WARNING ****\nTimezoneStore.instance will be removed in 3.0. Please instantiate a TimezoneStore object."
      @instance ||= new
    end

    def self.store(timezone)
      warn "**** DEPRECATION WARNING ****\nTimezoneStore.store will be removed in 3.0. Please use instance methods."
      instance.store timezone
    end

    def self.retrieve(tzid)
      warn "**** DEPRECATION WARNING ****\nTimezoneStore.retrieve will be removed in 3.0. Please use instance methods."
      instance.retrieve tzid
    end

    def store(timezone)
      self[timezone.tzid] = timezone
    end

    def retrieve(tzid)
      self[tzid]
    end

  end

end
