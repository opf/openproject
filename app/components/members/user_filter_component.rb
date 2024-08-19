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

module Members
  class UserFilterComponent < ::UserFilterComponent
    ALL_SHARED_FILTER_KEY = "all"

    def initially_visible?
      false
    end

    def has_close_icon?
      true
    end

    def has_shares?
      true
    end

    def shares
      @shares ||= self.class.share_options
    end

    ##
    # Adapts the user filter counts to count members as opposed to users.
    def extra_user_status_options
      {
        all: status_members_query("all").count,
        blocked: status_members_query("blocked").count,
        active: status_members_query("active").count,
        invited: status_members_query("invited").count,
        registered: status_members_query("registered").count,
        locked: status_members_query("locked").count
      }
    end

    def status_members_query(status)
      params = {
        project_id: project.id,
        status:
      }

      self.class.filter(params)
    end

    def filter_path
      project_members_path(project)
    end

    class << self
      def base_query
        Queries::Members::MemberQuery
      end

      def filter_param_keys
        super + %i(shared_role_id)
      end

      def share_options
        share_options = WorkPackageRole
          .where(builtin: builtin_share_roles)
          .order(builtin: :asc)
          .map { |role| [mapped_shared_role_name(role), role.id] }

        share_options.unshift([I18n.t("members.filters.all_shares"), ALL_SHARED_FILTER_KEY])
      end

      def builtin_share_roles
        [
          Role::BUILTIN_WORK_PACKAGE_VIEWER,
          Role::BUILTIN_WORK_PACKAGE_COMMENTER,
          Role::BUILTIN_WORK_PACKAGE_EDITOR
        ].freeze
      end

      def mapped_shared_role_name(role)
        case role.builtin
        when Role::BUILTIN_WORK_PACKAGE_VIEWER
          I18n.t("work_package.permissions.view")
        when Role::BUILTIN_WORK_PACKAGE_COMMENTER
          I18n.t("work_package.permissions.comment")
        when Role::BUILTIN_WORK_PACKAGE_EDITOR
          I18n.t("work_package.permissions.edit")
        else
          role.name
        end
      end

      protected

      def filter_shares(query, role_id)
        if role_id === ALL_SHARED_FILTER_KEY
          ids = WorkPackageRole
                  .where(builtin: builtin_share_roles)
                  .pluck(:id)

          query.where(:role_id, "=", ids.uniq)
        elsif role_id.to_i > 0
          query.where(:role_id, "=", role_id.to_i)
        end
      end

      def apply_filters(params, query)
        super
        filter_shares(query, params[:shared_role_id]) if params.key?(:shared_role_id)

        query
      end
    end
  end
end
