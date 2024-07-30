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
    module Users
      class UserSqlRepresenter
        include API::Decorators::Sql::Hal

        class << self
          def user_name_projection(*)
            case Setting.user_format
            when :firstname_lastname
              "concat(firstname, ' ', lastname)"
            when :firstname
              "firstname"
            when :lastname_firstname
              "concat(lastname, ' ', firstname)"
            when :lastname_coma_firstname
              "concat(lastname, ', ', firstname)"
            when :lastname_n_firstname
              "concat_ws(lastname, '', firstname)"
            when :username
              "login"
            else
              raise ArgumentError, "Invalid user format"
            end
          end

          def render_if_manage_user_or_self(*)
            if User.current.allowed_globally?(:manage_user)
              "TRUE"
            else
              "id = #{User.current.id}"
            end
          end
        end

        link :self,
             path: { api: :user, params: %w(id) },
             column: -> { :id },
             title: method(:user_name_projection)

        property :_type,
                 representation: ->(*) { "'User'" }

        property :id

        property :name,
                 representation: method(:user_name_projection)

        property :firstname,
                 render_if: method(:render_if_manage_user_or_self)

        property :lastname,
                 render_if: method(:render_if_manage_user_or_self)
      end
    end
  end
end
