# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

module WorkPackages
  module Share
    # rubocop:disable OpenProject/AddPreviewForViewComponent
    class UserDetailsComponent < ApplicationComponent
      # rubocop:enable OpenProject/AddPreviewForViewComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include WorkPackages::Share::Concerns::DisplayableRoles

      def initialize(share:,
                     manager_mode: User.current.allowed_in_project?(:share_work_packages, share.project),
                     invite_resent: false)
        super

        @share = share
        @user = share.principal
        @manager_mode = manager_mode
        @invite_resent = invite_resent
      end

      private

      attr_reader :user, :share

      def manager_mode? = @manager_mode

      def invite_resent? = @invite_resent

      def wrapper_uniq_by
        share.id
      end

      def authoritative_work_package_role_name
        @authoritative_work_package_role_name = options.find do |option|
          option[:value] == share.roles.first.builtin
        end[:label]
      end

      def principal_show_path
        case user
        when User
          user_path(user)
        when Group
          show_group_path(user)
        else
          placeholder_user_path(user)
        end
      end

      def resend_invite_path
        resend_invite_work_package_share_path(share.entity, share)
      end

      def user_is_a_group?
        @user_is_a_group ||= user.is_a?(Group)
      end

      def user_in_non_active_status?
        user.locked? || user.invited?
      end

      # Is a user member of a project no matter whether inherited or directly assigned
      def project_member?
        Member.exists?(project: share.project,
                       principal: user,
                       entity: nil)
      end

      # Explicitly check whether the project membership was inherited by a group
      def inherited_project_member?
        Member.includes(:roles)
              .references(:member_roles)
              .where(project: share.project, principal: user, entity: nil) # membership in the project
              .merge(MemberRole.only_inherited) # that was inherited
              .any?
      end

      def project_group?
        user_is_a_group? && project_member?
      end

      def part_of_a_shared_group?
        share.member_roles.where.not(inherited_from: nil).any?
      end

      def part_of_a_group?
        GroupUser.where(user_id: user.id).any?
      end

      def project_role_name
        Member.where(project: share.project,
                     principal: user,
                     entity: nil)
              .first
              .roles
              .first
              .name
      end
    end
  end
end
