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

module Projects::Copy
  class MembersDependentService < Dependency
    def self.human_name
      I18n.t(:"projects.copy.members")
    end

    def source_memberships
      source.memberships.of_any_project
    end

    def source_count
      source_memberships.count
    end

    protected

    def copy_dependency(*)
      # Ensure we get the default role added for the copied project
      target.members.reload

      # Copy users and placeholder users first,
      # then groups to handle members with inherited and given roles
      source_memberships.sort_by { |m| m.principal.is_a?(Group) ? 1 : 0 }.each do |member|
        create_membership(member)
      end
    end

    def create_membership(member) # rubocop:disable Metrics/AbcSize
      # only copy non inherited roles
      # inherited roles will be added when copying the group membership
      role_ids = member.member_roles
                       .reject(&:inherited?)
                       .reject { |mr| excluded_role_ids.include?(mr.role_id) }
                       .map(&:role_id)
      return if role_ids.empty?

      # There should only be zero or one members in this new project
      # which gets created from the default +ProjectRole.in_new_project+ if enabled.
      target_member = target.members.detect { |m| m.principal == member.principal }
      if target_member
        Members::UpdateService
          .new(model: target_member, user: User.current, contract_class: EmptyContract)
          .call(role_ids: (target_member.role_ids + role_ids).uniq)
      else
        attributes = member
          .attributes.dup.except("id", "project_id", "created_at", "updated_at")
          .merge(role_ids:, project: target)

        Members::CreateService
          .new(user: User.current, contract_class: EmptyContract)
          .call(attributes)
      end
    end

    def excluded_role_ids
      @excluded_role_ids ||= Array(source.excluded_role_ids_on_copy).map(&:to_i)
    end
  end
end
