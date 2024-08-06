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
      scope = %i[sharing user_details]

      return I18n.t(:invited, scope:) if !manageable? && share.principal.invited?
      return "" if !manageable?

      if share.principal.is_a?(Group)
        if project_member?(share)
          I18n.t(:project_group, scope:)
        else
          I18n.t(:not_project_group, scope:)
        end

      elsif group_member?(share)
        if has_roles_via_group_membership?(share)
          if project_member?(share)
            I18n.t(:additional_privileges_project_or_group, scope:)
          else
            I18n.t(:additional_privileges_group, scope:)
          end
        elsif inherited_project_member?(share)
          I18n.t(:additional_privileges_project_or_group, scope:)
        elsif project_member?(share)
          I18n.t(:additional_privileges_project, scope:)
        else
          I18n.t(:not_project_member, scope:)
        end
      elsif project_member?(share)
        I18n.t(:additional_privileges_project, scope:)
      else
        I18n.t(:not_project_member, scope:)
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

    def modal_body_component(errors)
      if EnterpriseToken.allows_to?(:work_package_sharing)
        super
      else
        Shares::WorkPackages::ModalUpsaleComponent.new
      end
    end

    def title
      I18n.t(:label_share_work_package)
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
