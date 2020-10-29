require 'delegate'
require 'icalendar/downcased_hash'

module Icalendar

  class Value < ::SimpleDelegator

    attr_accessor :ical_params

    def initialize(value, params = {})
      @ical_params = Icalendar::DowncasedHash(params)
      super value
    end

    def ical_param(key, value)
      @ical_params[key] = value
    end

    def value
      __getobj__
    end

    def to_ical(default_type)
      ical_param 'value', self.value_type if needs_value_type?(default_type)
      "#{params_ical}:#{value_ical}"
    end

    def params_ical
      unless ical_params.empty?
        ";#{ical_params.map { |name, value| param_ical name, value }.join ';'}"
      end
    end

    def self.value_type
      name.gsub(/\A.*::/, '').gsub(/(?<!\A)[A-Z]/, '-\0').upcase
    end

    def value_type
      self.class.value_type
    end

    private

    def needs_value_type?(default_type)
      self.class != default_type
    end

    def param_ical(name, param_value)
      if param_value.is_a? Array
        param_value = param_value.map { |v| escape_param_value v }.join ','
      else
        param_value = escape_param_value param_value
      end
      "#{name.to_s.gsub('_', '-').upcase}=#{param_value}"
    end

    def escape_param_value(value)
      v = value.to_s.gsub('"', "'")
      v =~ /[;:,]/ ? %("#{v}") : v
    end

  end

end

# helpers; not actual iCalendar value type
require_relative 'values/array'
require_relative 'values/date_or_date_time'

# iCalendar value types
require_relative 'values/binary'
require_relative 'values/boolean'
require_relative 'values/date'
require_relative 'values/date_time'
require_relative 'values/duration'
require_relative 'values/float'
require_relative 'values/integer'
require_relative 'values/period'
require_relative 'values/recur'
require_relative 'values/text'
require_relative 'values/time'
require_relative 'values/uri'
require_relative 'values/utc_offset'

# further refine above classes
require_relative 'values/cal_address'
