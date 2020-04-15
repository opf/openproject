#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::Patches::UpdateServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def update_descendants
      super_result = super

      if work_package.in_backlogs_type? && work_package.version_id_changed?
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

      attributes = { version_id: work_package.version_id }

      descendant_tasks.each do |task|
        result.add_dependent!(set_attributes(attributes, task))
      end
    end
  end
end



