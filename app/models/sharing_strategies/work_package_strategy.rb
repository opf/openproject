#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module SharingStrategies
  class WorkPackageStrategy < BaseStrategy
    def available_roles
      role_mapping = WorkPackageRole.unscoped.pluck(:builtin, :id).to_h

      [
        { label: I18n.t("work_package.permissions.edit"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_EDITOR],
          description: I18n.t("work_package.permissions.edit_description") },
        { label: I18n.t("work_package.permissions.comment"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_COMMENTER],
          description: I18n.t("work_package.permissions.comment_description") },
        { label: I18n.t("work_package.permissions.view"),
          value: role_mapping[Role::BUILTIN_WORK_PACKAGE_VIEWER],
          description: I18n.t("work_package.permissions.view_description"),
          default: true }
      ]
    end

    def manageable?
      user.allowed_in_project?(:share_work_packages, @entity.project)
    end

    def viewable?
      user.allowed_in_project?(:view_shared_work_packages, @entity.project)
    end

    def share_description(share) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize
      return I18n.t("sharing.user_details.invited") if !manageable? && share.principal.invited?
      return "" if !manageable?

      if share.principal.is_a?(Group)
        if project_member?(share)
          I18n.t("sharing.user_details.project_group")
        else
          I18n.t("sharing.user_details.not_project_group")
        end

      elsif group_member?(share)
        if has_roles_via_group_membership?(share)
          if project_member?(share)
            I18n.t("sharing.user_details.additional_privileges_project_or_group")
          else
            I18n.t("sharing.user_details.additional_privileges_group")
          end
        elsif inherited_project_member?(share)
          I18n.t("sharing.user_details.additional_privileges_project_or_group")
        elsif project_member?(share)
          I18n.t("sharing.user_details.additional_privileges_project")
        else
          I18n.t("sharing.user_details.not_project_member")
        end
      elsif project_member?(share)
        I18n.t("sharing.user_details.additional_privileges_project")
      else
        I18n.t("sharing.user_details.not_project_member")
      end
    end

    def create_contract_class
      Shares::WorkPackages::CreateContract
    end

    def update_contract_class
      Shares::WorkPackages::UpdateContract
    end

    def delete_contract_class
      Shares::WorkPackages::DeleteContract
    end

    private

    def project_member?(share)
      Member.exists?(project: share.entity.project, principal: share.principal, entity: nil)
    end

    def group_member?(share)
      GroupUser.where(user_id: share.principal.id).any?
    end

    def has_roles_via_group_membership?(share)
      share.member_roles.where.not(inherited_from: nil).any?
    end

    def inherited_project_member?(share)
      Member.includes(:roles)
            .references(:member_roles)
            .where(project: share.project, principal: share.principal, entity: nil)
            .merge(MemberRole.only_inherited)
            .any?
    end
  end
end
