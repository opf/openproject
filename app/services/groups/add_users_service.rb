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
      sql_query = ::OpenProject::SqlSanitization
                    .sanitize add_to_group,
                              group_id: model.id,
                              user_ids: params[:ids]
      execute_query(sql_query)

      call
    end

    def after_perform(call)
      Groups::CreateInheritedRolesService
        .new(model, current_user: user, contract_class:)
        .call(
          user_ids: params[:ids],
          message: params[:message]
        )

      call
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
