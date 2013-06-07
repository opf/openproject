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

module Redmine
  module AccessKeys
    ACCESSKEYS = {:edit => '3',
                  :preview => '1',
                  :quick_search => '4',
                  :help => '6',
                  :new_issue => '2'
                 }.freeze unless const_defined?(:ACCESSKEYS)

    def self.key_for(action)
      ACCESSKEYS[action]
    end
  end
end
