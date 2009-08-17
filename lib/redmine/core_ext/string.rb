require File.dirname(__FILE__) + '/string/conversions'
require File.dirname(__FILE__) + '/string/inflections'

class String #:nodoc:
  include Redmine::CoreExtensions::String::Conversions
  include Redmine::CoreExtensions::String::Inflections
end
