#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module AccessKeys
    ACCESSKEYS = {:edit => 'e',
                  :preview => 'r',
                  :quick_search => 'f',
                  :search => '4',
                  :new_issue => '7'
                 }.freeze unless const_defined?(:ACCESSKEYS)

    def self.key_for(action)
      ACCESSKEYS[action]
    end
  end
end
