#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

module OpenProject::Backlogs::Patches::SetAttributesServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def set_attributes(attributes)
      super

      if work_package.parent_id_changed? &&
         work_package.parent_id &&
         !work_package.fixed_version_id_changed? &&
         work_package.in_backlogs_type?

        closest = closest_story_or_impediment(work_package.parent_id)
        work_package.fixed_version_id = closest.fixed_version_id if closest
      end
    end

    def closest_story_or_impediment(parent_id)
      return work_package if work_package.is_story? || work_package.is_impediment?
      closest = nil
      ancestor_chain(parent_id).each do |i|
        # break if we found an element in our chain that is not relevant in backlogs
        break unless i.in_backlogs_type?
        if i.is_story? || i.is_impediment?
          closest = i
          break
        end
      end
      closest
    end

    # ancestors array similar to Module#ancestors
    # i.e. returns immediate ancestors first
    def ancestor_chain(parent_id)
      ancestors = []
      unless parent_id.nil?
        real_parent = WorkPackage.find_by(id: parent_id)

        # Sort immediate ancestors first
        ancestors = real_parent
                    .ancestors
                    .includes(project: :enabled_modules)
                    .order_by_ancestors('desc')
                    .select('work_packages.*, COALESCE(max_depth.depth, 0)')

        ancestors = [real_parent] + ancestors
      end
      ancestors
    end
  end
end



