require 'date'

module ToDatePatch
  module StringAndNil
    ::String.send(:include, self)
    ::NilClass.send(:include, self)

    def to_dateish
      return Date.today if blank?
      Date.parse self
    end
  end

  module DateAndTime
    ::Date.send(:include, self)
    ::Time.send(:include, self)
  
    def to_dateish
      self
    end

    def force_utc
      return to_time.force_utc unless respond_to? :utc_offset
      return self if utc?
      utc - utc_offset
    end
  end
end
