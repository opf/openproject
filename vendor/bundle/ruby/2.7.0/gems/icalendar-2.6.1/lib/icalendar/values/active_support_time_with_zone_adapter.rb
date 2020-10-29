module Icalendar
  module Values
    class ActiveSupportTimeWithZoneAdapter < ActiveSupport::TimeWithZone
      # ActiveSupport::TimeWithZone implements a #to_a method that will cause
      # unexpected behavior in components with multi_property DateTime
      # properties when the setters for those properties are invoked with an
      # Icalendar::Values::DateTime that is delegating for an
      # ActiveSupport::TimeWithZone. To avoid this behavior, undefine #to_a.
      undef_method :to_a
    end
  end
end
