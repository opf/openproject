#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/string/conversions'
require File.dirname(__FILE__) + '/string/inflections'

class String #:nodoc:
  include Redmine::CoreExtensions::String::Conversions
  include Redmine::CoreExtensions::String::Inflections
end
