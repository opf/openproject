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

module Grids
  module Widgets
    class Members < Grids::WidgetComponent
      MEMBERS_LIMIT = 3
      private_constant :MEMBERS_LIMIT

      param :project

      option :limit, default: -> { MEMBERS_LIMIT }

      def title
        t(".title")
      end

      def members_by_role # rubocop:disable Metrics/AbcSize
        # Sanity check: If we can't view members, we can return immediatly.
        # This way we don't need to check if current_user is allowed to view_members
        # multiple times.
        return [] unless can_view_members?

        @members_by_role ||= ProjectRole
          .joins(:members)
          .where(members: { project_id: project.id })
          .group(:id, :name)
          .order(name: :asc)
          .count
          .filter_map do |(id, name), total_count|
            members = principals_for_role(id).limit(limit).load
            next if members.none?

            {
              id:,
              name:,
              members:,
              total_count: total_count,
              remaining: [total_count - limit, 0].max,
              has_more: total_count > limit
            }
          end
      end

      def principals_for_role(role_id)
        # NOTE: The principals scope on Project joins members and
        #       since we need also member_roles, we would need to
        #       join members again, resulting in principals being
        #       included multiple times (e.g. when having the same
        #       role in multiple projects).
        Principal
          .not_locked
          .joins(members: :member_roles)
          .where(members: { project: })
          .where(member_roles: { role_id: })
          .order(members: { created_at: :desc })
      end

      def can_view_members?
        current_user.allowed_in_project?(:view_members, project)
      end

      def can_manage_members?
        @can_manage_members ||= current_user.allowed_in_project?(:manage_members, project)
      end
    end
  end
end
