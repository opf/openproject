require File.dirname(__FILE__) + '/string/conversions'

class String #:nodoc:
  include Redmine::CoreExtensions::String::Conversions
end
