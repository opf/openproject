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

module Roles
  module DeleteDialog
    class ProjectRoleContentComponent < ContentComponent
      PROJECT_LIMIT = 3

      def project_count
        @project_count ||= members.distinct.count(:project_id)
      end

      def entries
        @entries ||= members
                       .includes(:project)
                       .group_by(&:principal)
                       .map { |principal, principal_members| build_entry(principal, principal_members) }
      end

      def summary
        I18n.t("roles.delete_dialog.summary",
               users: I18n.t("roles.delete_dialog.summary_users", count: principal_count),
               projects: I18n.t("roles.delete_dialog.summary_projects", count: project_count))
      end

      def conclusion
        I18n.t("roles.delete_dialog.losing_project_access", count: principals_losing_access_count)
      end

      def principals_losing_access_count
        @principals_losing_access_count ||= members_losing_access.distinct.count(:user_id)
      end

      # Rendered next to, but styled apart from, the principal's name.
      def projects_label(entry)
        projects = entry[:projects]
        listed = projects.first(PROJECT_LIMIT).map(&:name).join(", ")
        remaining = projects.size - PROJECT_LIMIT

        if remaining.positive?
          I18n.t("roles.delete_dialog.entry_projects_truncated", projects: listed, count: remaining)
        else
          I18n.t("roles.delete_dialog.entry_projects", projects: listed, count: projects.size)
        end
      end

      private

      # A member loses its access once the role being deleted is the last one it holds.
      def members_losing_access
        members.where.not(id: MemberRole.where.not(role_id: role.id).select(:member_id))
      end

      def build_entry(principal, principal_members)
        { principal:, projects: principal_members.filter_map(&:project).uniq.sort_by(&:name) }
      end
    end
  end
end
