##
# A minimal ReportingHelper module. This is included in Widget and
# Controller and can be used to extend the specific widgets and
# controller functionality.
#
# It is the default hook for translations, and calls to l() in Widgets
# or Controllers will go to this module, first. The default behavior
# is to pass translation work on to I18n.t() or I18n.l(), depending on
# the type of arguments.
module ReportingHelper
  def l(*values)
    return values.first if values.size == 1 and values.first.respond_to? :to_str
    if [Date, DateTime, Time].include? values.first.class
      ::I18n.l(values.first)
    else
      ::I18n.t(*values)
    end
  end
end
