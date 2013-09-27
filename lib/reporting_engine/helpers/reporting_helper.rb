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
end
