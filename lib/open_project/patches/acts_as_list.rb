#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# This patch adds a convenience method to models that are including acts_as_list.
# After including it is possible to e.g. call
#
# including_instance.move_to = "highest"
#
# and the instance will be sorted to to the top of the list.
#
# This enables having the view send string that will be used for sorting.

# Needs to be applied before any of the models using acts_as_list get loaded.

module OpenProject
  module Patches
    module ActsAsList
      def move_to=(pos)
        pos = pos.to_sym

        case pos
        when :highest
          move_to_top
        when :lowest
          move_to_bottom
        when :higher
          move_higher
        when :lower
          move_lower
        end
      end
    end
  end
end

ActiveRecord::Acts::List::InstanceMethods.send(:include, OpenProject::Patches::ActsAsList)
