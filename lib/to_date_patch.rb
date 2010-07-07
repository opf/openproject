require 'date'

module ToDatePatch
  ::String.send(:include, self)
  ::NilClass.send(:include, self)

  def to_date
    return Date.today if blank?
    Date.parse self
  end
end
