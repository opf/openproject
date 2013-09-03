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

RAILS_ENV = "test" unless defined? RAILS_ENV

require "spec_helper"
Dir[File.dirname(__FILE__) + '/support/*.rb'].each {|file| require file }
