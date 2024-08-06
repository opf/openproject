#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::Backlogs::Patches::UpdateServicePatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def update_descendants(work_package)
      super_result = super

      if work_package.in_backlogs_type? && work_package.saved_change_to_version_id?
        super_result += inherit_version_to_descendants(work_package)
      end

      super_result
    end

    def inherit_version_to_descendants(work_package)
      all_descendants = sorted_descendants(work_package)
      descendant_tasks = descendant_tasks_of(all_descendants)

      attributes = { version_id: work_package.version_id }

      descendant_tasks.map do |task|
        # Ensure the parent is already moved to new version so that validation errors are avoided.
        task.parent = ([work_package] + all_descendants).detect { |d| d.id == task.parent_id }
        set_descendant_attributes(attributes, task)
      end
    end

    def sorted_descendants(work_package)
      work_package
        .descendants
        .includes(project: :enabled_modules)
        .order_by_ancestors("asc")
        .select("work_packages.*")
    end

    def descendant_tasks_of(descendants)
      stop_descendants_ids = []

      descendants.reject do |t|
        if stop_descendants_ids.include?(t.parent_id) || !t.is_task?
          stop_descendants_ids << t.id
        end
      end
    end
  end
end
