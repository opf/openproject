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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

      def members_by_role
        @members_by_role ||= ProjectRole
          .where(id: member_role_ids)
          .order(name: :asc)
          .map do |role|
          members_query = members_for_role(role.id)
          total_count = members_query.count
          members = members_query.limit(limit).to_a.map(&:principal)

          {
            role:,
            members:,
            total_count:,
            remaining: [total_count - limit, 0].max,
            has_more: total_count > limit
          }
        end
      end

      def members_for_role(role_id)
        project
          .members
          .visible(current_user)
          .joins(:member_roles)
          .where(member_roles: { role_id: })
          .includes(:principal)
          .order(created_at: :desc)
      end

      def member_role_ids
        MemberRole
          .where(member_id: project.members.select(:id))
          .select(:role_id)
          .distinct
      end

      def can_view_members?
        current_user.allowed_in_project?(:view_members, project)
      end

      def can_manage_members?
        current_user.allowed_in_project?(:manage_members, project)
      end
    end
  end
end
