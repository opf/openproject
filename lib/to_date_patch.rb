require 'date'

module ToDatePatch
  module StringAndNil
    ::String.send(:include, self)
    ::NilClass.send(:include, self)

    def to_dateish
      return Date.today if blank?
      Date.parse self
    end

    def force_utc
      return self if utc?
      utc - utc_offset
    end
  end

  module DateAndTime
    ::Date.send(:include, self)
    ::Time.send(:include, self)
  
    def to_dateish
      self
    end
  end
end
