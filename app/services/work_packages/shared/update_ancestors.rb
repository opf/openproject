# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Shared
    module UpdateAncestors
      # Update ancestors for the given work package according to the given
      # changed attributes.
      #
      # @param work_package [WorkPackage] the work package to update the
      #   ancestors of
      # @param changed_attributes [Array<Symbol>] the attributes that have been
      #   changed on the work package. If nil, all the attributes of the work
      #   package will be used.
      # @return [ServiceResult] the result of the `UpdateAncestorsService` call
      def update_ancestors(work_package, changed_attributes = nil)
        changed_attributes ||= work_package.attribute_keys
        WorkPackages::UpdateAncestorsService
          .new(user:, work_package:)
          .with_state(state)
          .call(changed_attributes)
      end

      # Update ancestors for multiple work packages, taking care of not updating
      # the same work package twice.
      # Always calls `UpdateAncestorsService` with changed attributes being all
      # attributes.
      #
      # @param work_packages [Array<WorkPackage>] the work packages to update
      #   the ancestors of
      # @return [Array<ServiceResult>] the results of the
      #   `UpdateAncestorsService` calls
      def multi_update_ancestors(work_packages)
        updated_work_package_ids = Set.new
        work_packages.filter_map do |work_package|
          next if updated_work_package_ids.include?(work_package.id)

          update_ancestors(work_package).tap do |result|
            updated_work_package_ids.merge(result.all_results.map(&:id))
          end
        end
      end
    end
  end
end
