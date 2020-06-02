#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Groups
  class AddUsersService < ::BaseServices::BaseContracted
    attr_reader :group

    def initialize(group, current_user:)
      @group = group

      super user: current_user,
            contract_class: BaseContract
    end

    def after_validate(user_ids, _call)
      ::Group.transaction do
        add_to_user_and_projects(user_ids)
      end
    end

    def model
      group
    end

    private

    ##
    # Add users as the same members to the projects
    # the group is a member of
    def add_to_user_and_projects(user_ids)
      exec_query!(user_ids)
      ServiceResult.new success: true, result: group
    rescue StandardError => e
      Rails.logger.error { "Failed to add users to group #{group.id}: #{e} #{e.message}" }
      ServiceResult.new(success: false, message: I18n.t(:notice_internal_server_error, app_title: Setting.app_title))
    end

    def exec_query!(user_ids)
      sql_query = ::OpenProject::SqlSanitization
        .sanitize add_to_user_and_projects_cte, group_id: group.id, user_ids: user_ids

      ::Group.connection.exec_query(sql_query)
    end

    def add_to_user_and_projects_cte
      <<~SQL
        -- select existing users from given IDs
        WITH found_users AS (
          SELECT id as user_id FROM #{User.table_name} WHERE id IN (:user_ids)
        ),
        -- select existing memberships of the group
        group_memberships AS (
          SELECT project_id, user_id FROM #{Member.table_name} WHERE user_id = :group_id
        ),
        -- select existing member_roles of the group
        group_roles AS (
          SELECT members.project_id AS project_id,
                 members.user_id AS user_id,
                 members.id AS member_id,
                 member_roles.role_id AS role_id
          FROM #{MemberRole.table_name} member_roles
          JOIN #{Member.table_name} members
          ON members.id = member_roles.member_id AND members.user_id = :group_id
        ),
        -- insert into group_users association
        new_group_users AS (
          INSERT INTO group_users (group_id, user_id)
          SELECT :group_id as group_id, user_id FROM found_users
          ON CONFLICT DO NOTHING
        ),
        -- insert the group user into members
        new_members AS (
          INSERT INTO #{Member.table_name} (project_id, user_id)
          SELECT group_memberships.project_id, found_users.user_id
          FROM found_users, group_memberships
          -- We need to return all members for the given group memberships
          -- even if they already exist as members (e.g., added individually) to ensure we add all roles
          -- to mark that we reset the created_at date since replacing the member
          ON CONFLICT(project_id, user_id) DO UPDATE SET created_on = CURRENT_TIMESTAMP
          RETURNING id, user_id
        )
        -- copy the member roles of the group
        INSERT INTO #{MemberRole.table_name} (member_id, role_id, inherited_from)
        SELECT new_members.id, group_roles.role_id, group_roles.member_id
        FROM group_roles, new_members
        -- Ignore if the role was already inserted by us
        ON CONFLICT DO NOTHING
      SQL
    end
  end
end
