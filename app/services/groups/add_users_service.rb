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

module Groups
  class AddUsersService < ::BaseServices::BaseContracted
    using CoreExtensions::SquishSql

    def initialize(group, current_user:, contract_class: AdminOnlyContract)
      self.model = group

      super(user: current_user,
            contract_class:)
    end

    private

    def persist(call)
      validate_department_membership(call)
      return call unless call.success?

      sql_query = ::OpenProject::SqlSanitization
                    .sanitize add_to_group,
                              group_id: model.id,
                              user_ids: params[:ids]
      execute_query(sql_query)

      call
    end

    # The same validation exists in Groups::BaseContract, but it relies on in-memory
    # group_users that are new_record?. This service inserts group_users via raw SQL,
    # so the contract never sees them. We duplicate the check here against the params directly.
    def validate_department_membership(call)
      return unless model.organizational_unit?

      conflicts = users_already_in_departments(params[:ids])

      conflicts.each do |user_id, department_id|
        call.errors.add(:group_users, :user_already_in_department, user_id:, department_id:)
      end

      call.success = false if conflicts.any?
    end

    def users_already_in_departments(user_ids)
      GroupUser
        .joins(:group)
        .merge(Group.organizational_units)
        .where(user_id: user_ids)
        .where.not(group_id: model.id)
        .pluck(:user_id, :group_id)
    end

    def after_perform(call)
      create_inherited_roles(model)

      model.ancestors.each do |ancestor|
        create_inherited_roles(ancestor)
      end

      call
    end

    def create_inherited_roles(group)
      Groups::CreateInheritedRolesService
        .new(group, current_user: user, contract_class:)
        .call(user_ids: params[:ids], message: params[:message])
    end

    def add_to_group
      <<~SQL.squish
        INSERT INTO group_users (group_id, user_id)
        SELECT :group_id as group_id, user_id FROM
          (SELECT id as user_id FROM #{User.table_name} WHERE id IN (:user_ids)) users
        ON CONFLICT DO NOTHING
      SQL
    end

    def execute_query(query)
      ::Group
        .connection
        .exec_query(query)
    end
  end
end
