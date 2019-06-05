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

module OpenProject::Backlogs::Patches::UpdateServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def update_descendants
      super_result = super

      if work_package.in_backlogs_type? && work_package.fixed_version_id_changed?
        inherit_version_to_descendants(super_result)
      end

      super_result
    end

    def inherit_version_to_descendants(result)
      all_descendants = work_package
                          .descendants
                          .includes(:parent_relation, project: :enabled_modules)
                          .order(Arel.sql('relations.hierarchy asc'))
                          .select('work_packages.*, relations.hierarchy')
      stop_descendants_ids = []

      descendant_tasks = all_descendants.reject do |t|
        if stop_descendants_ids.include?(t.parent_relation.from_id) || !t.is_task?
          stop_descendants_ids << t.id
        end
      end

      attributes = { fixed_version_id: work_package.fixed_version_id }

      descendant_tasks.each do |task|
        result.add_dependent!(set_attributes(attributes, task))
      end
    end
  end
end



