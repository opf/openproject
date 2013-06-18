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

#-- encoding: UTF-8
# Include hook code here
require File.dirname(__FILE__) + '/lib/acts_as_watchable'
require File.dirname(__FILE__) + '/lib/acts_as_watchable/routes.rb'

ActiveRecord::Base.send(:include, Redmine::Acts::Watchable)
