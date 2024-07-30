#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module API
  module V3
    module Principals
      # This representer is able to render all the concrete classes of Principal: User, Group and PlaceholderUser.
      class PrincipalSqlRepresenter
        include API::Decorators::Sql::Hal

        class << self
          def select_sql(select, walker_result)
            <<~SELECT
              json_strip_nulls(
                CASE
                WHEN type = 'Group' THEN json_build_object(#{group_select_sql(select, walker_result)})
                WHEN type = 'PlaceholderUser' THEN json_build_object(#{placeholder_user_select_sql(select, walker_result)})
                WHEN type = 'User' THEN json_build_object(#{user_select_sql(select, walker_result)})
                END
              )::jsonb - '#{API::Decorators::Sql::Hal::TO_BE_REMOVED}'
            SELECT
          end

          private

          def group_select_sql(select, walker_result)
            API::V3::Groups::GroupSqlRepresenter.json_object_string(select, walker_result)
          end

          def placeholder_user_select_sql(select, walker_result)
            API::V3::PlaceholderUsers::PlaceholderUserSqlRepresenter.json_object_string(select, walker_result)
          end

          def user_select_sql(select, walker_result)
            API::V3::Users::UserSqlRepresenter.json_object_string(select, walker_result)
          end

          def valid_selects
            API::V3::Groups::GroupSqlRepresenter.valid_selects &
              API::V3::PlaceholderUsers::PlaceholderUserSqlRepresenter.valid_selects &
              API::V3::Users::UserSqlRepresenter.valid_selects
          end
        end
      end
    end
  end
end
