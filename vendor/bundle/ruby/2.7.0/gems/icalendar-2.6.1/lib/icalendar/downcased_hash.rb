require 'delegate'

module Icalendar
  class DowncasedHash < ::SimpleDelegator

    def initialize(base)
      super Hash.new
      base.each do |key, value|
        self[key] = value
      end
    end

    def []=(key, value)
      __getobj__[key.to_s.downcase] = value
    end

    def [](key)
      __getobj__[key.to_s.downcase]
    end

    def has_key?(key)
      __getobj__.has_key? key.to_s.downcase
    end
    alias_method :include?, :has_key?
    alias_method :member?, :has_key?

    def delete(key, &block)
      __getobj__.delete key.to_s.downcase, &block
    end
  end

  def self.DowncasedHash(base)
    case base
    when Icalendar::DowncasedHash then base
    when Hash then Icalendar::DowncasedHash.new(base)
    else
      fail ArgumentError
    end
  end
end
