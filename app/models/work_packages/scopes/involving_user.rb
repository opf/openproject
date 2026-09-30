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
#

module WorkPackages::Scopes
  module InvolvingUser
    extend ActiveSupport::Concern

    class_methods do
      # Fetches all work packages for which a user is assigned to, responsible
      # for, or watcher, via a group or themself
      #
      # @param user User the user involved in work packages.
      def involving_user(user) # rubocop:disable Metrics/AbcSize
        # Using CTEs and UNION for performance reasons
        # The alternative would be the simpler:
        # ```
        # WorkPackage
        #   .left_joins(:watchers)
        #   .where(watchers: { user: })
        #   .or(WorkPackage.where(assigned_to: user))
        #   .or(WorkPackage.where(assigned_to: group_having(user)))
        #   .or(WorkPackage.where(responsible: user))
        #   .or(WorkPackage.where(responsible: group_having(user)))
        # ```
        # That however prevents indices from being used because of the or clauses on different columns.
        watched = WorkPackage
                    .left_joins(:watchers)
                    .where(watchers: { user: })
                    .select(:id)
        assigned = WorkPackage
                     .where("assigned_to_id IN (SELECT * FROM user_and_groups)")
                     .select(:id)
        responsible = WorkPackage
                        .where("responsible_id IN (SELECT * FROM user_and_groups)")
                        .select(:id)

        watched_and_assigned_and_responsible = Arel::Nodes::Union.new(watched.arel,
                                                                      Arel::Nodes::Union.new(assigned.arel,
                                                                                             responsible.arel))

        WorkPackage
          .with(user_and_groups: user_and_groups_union(user))
          .where(arel_table[:id].in(watched_and_assigned_and_responsible))
      end

      private

      def user_and_groups_union(user)
        in_group = GroupUser.select("group_id").where(["user_id = ?", user.id]) # rubocop:disable Rails/WhereEquals

        Arel.sql("#{in_group.to_sql} UNION SELECT #{user.id}")
      end
    end
  end
end
