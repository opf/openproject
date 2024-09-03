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

module WorkPackages
  module Shared
    module UpdateAncestors
      def update_ancestors(changed_work_packages)
        changes = changed_work_packages
                  .map { |wp| wp.previous_changes.keys }
                  .flatten
                  .uniq
                  .map(&:to_sym)

        update_each_ancestor(changed_work_packages, changes)
      end

      def update_ancestors_all_attributes(work_packages)
        changes = work_packages
                  .first
                  .attributes
                  .keys
                  .uniq
                  .map(&:to_sym)

        update_each_ancestor(work_packages, changes)
      end

      def update_each_ancestor(work_packages, changes)
        updated_work_package_ids = Set.new
        work_packages.filter_map do |wp|
          next if updated_work_package_ids.include?(wp.id)

          result = inherit_to_ancestors(wp, changes)
          updated_work_package_ids = updated_work_package_ids.merge(result.all_results.map(&:id))
          result
        end
      end

      def inherit_to_ancestors(wp, changes)
        WorkPackages::UpdateAncestorsService
          .new(user:,
               work_package: wp)
          .call(changes)
      end
    end
  end
end
