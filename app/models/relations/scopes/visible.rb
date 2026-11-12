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

module Relations::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Returns all relationships visible to the user. The relationships have to be:
      #   * Start (from_id) on a work package visible to the user (view_work_packages in the work package's project)
      #   * End (to_id) on a work package visible to the user (view_work_packages in the work package's project)
      #
      # In some cases, the resulting SQL query as is might not run in a performant matter. This happens in
      # cases where there are a lot of work packages and relations. PostgreSql then sometimes chooses to use a
      # full table scan on work_packages expecting a lot of results.
      # Then, the query can be optimized by providing a +work_package_focus_scope+ which is used as a subquery
      # on work_packages on the id column. This is beneficial if not all work packages are to be
      # considered but only a subset. As this directly excludes work packages, it can also be used
      # the wrong way.
      # @param [User] user
      # @param [ActiveRecord::Relation, Arel::SelectManager] work_package_focus_scope
      def visible(user = User.current, work_package_focus_scope: nil)
        visible_work_packages = WorkPackage.visible(user)

        wp_arel = work_package_focus_scope.respond_to?(:arel) ? work_package_focus_scope.arel : work_package_focus_scope
        visible_work_packages = visible_work_packages.where(WorkPackage.arel_table[:id].in(wp_arel)) if wp_arel

        with(visible_work_packages:)
          .where(from_id: WorkPackage.from("visible_work_packages #{WorkPackage.table_name}").select(:id))
          .where(to_id: WorkPackage.from("visible_work_packages #{WorkPackage.table_name}").select(:id))
      end
    end
  end
end
