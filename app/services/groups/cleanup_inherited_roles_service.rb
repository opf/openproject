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

# Deletes the roles granted to users by being part of a group.
# Will only delete the roles that are no longer granted so the group's membership needs to be deleted first.
# In case the user has roles independent of the group (not inherited) they are kept.
#
# This service is not specific to a certain group membership being removed. Rather, it will remove
# all MemberRole associations and in turn their Member associations if no matching inherited_from is found.

module Groups
  class CleanupInheritedRolesService < ::BaseServices::BaseContracted
    include Groups::Concerns::MembershipManipulation

    def initialize(group, current_user:, contract_class: AdminOnlyContract)
      self.model = group

      super(user: current_user,
            contract_class:)
    end

    private

    def modify_members_and_roles(params)
      affected_member_ids = execute_query(remove_member_roles_sql(params[:member_role_ids]))
      members_to_remove = members_to_remove(affected_member_ids)

      remove_members(members_to_remove)

      affected_member_ids - members_to_remove.map(&:id)
    end

    def remove_member_roles_sql(member_role_ids)
      if member_role_ids.present?
        sql_query = <<~SQL
          DELETE FROM #{MemberRole.table_name}
          WHERE id IN (:member_role_ids)
          RETURNING member_roles.member_id
        SQL

        ::OpenProject::SqlSanitization
          .sanitize sql_query,
                    member_role_ids:
      else
        <<~SQL
          DELETE FROM #{MemberRole.table_name}
          USING #{MemberRole.table_name} user_member_roles
          WHERE
            user_member_roles.inherited_from IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM #{MemberRole.table_name} group_member_roles WHERE group_member_roles.id = user_member_roles.inherited_from)
            AND user_member_roles.id = member_roles.id
          RETURNING member_roles.member_id
        SQL
      end
    end

    def members_to_remove(member_ids)
      Member
        .where(id: member_ids)
        .where.not(id: MemberRole.select(:member_id).distinct)
        .to_a
    end

    def remove_members(members)
      members.each do |member|
        Members::DeleteService
          .new(model: member, user:, contract_class: EmptyContract)
          .call
      end
    end
  end
end
