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
  module Decorators
    module Sql
      module HalAssociatedResource
        extend ActiveSupport::Concern

        class_methods do
          def associated_user_link(name,
                                   column_name: "#{name}_id")
            plural_name = name.to_s.pluralize

            link name,
                 href: associated_user_link_href(plural_name, column_name),
                 title: associated_user_link_title(plural_name),
                 join: associated_user_link_join(plural_name, column_name)
          end

          private

          def associated_user_link_href(table_name, column_name)
            ->(*) {
              <<~SQL.squish
                CASE #{table_name}_type
                WHEN 'Group' THEN format('#{api_v3_paths.group('%s')}', #{column_name})
                WHEN 'PlaceholderUser' THEN format('#{api_v3_paths.placeholder_user('%s')}', #{column_name})
                WHEN 'User' THEN format('#{api_v3_paths.user('%s')}', #{column_name})
                ELSE NULL
                END
              SQL
            }
          end

          def associated_user_link_title(table_name)
            -> {
              join_string = if Setting.user_format == :lastname_coma_firstname
                              " || ', ' || "
                            else
                              " || ' ' || "
                            end

              user_format = User::USER_FORMATS_STRUCTURE[Setting.user_format]
                              .map { |column| "#{table_name}_#{column}" }
                              .join(join_string)

              <<~SQL.squish
                CASE #{table_name}_type
                WHEN 'Group' THEN #{table_name}_lastname
                WHEN 'PlaceholderUser' THEN #{table_name}_lastname
                WHEN 'User' THEN #{user_format}
                ELSE NULL
                END
              SQL
            }
          end

          def associated_user_link_join(table_name, column_name)
            { table: :users,
              condition: "#{table_name}.id = #{column_name}",
              select: ["#{table_name}.firstname #{table_name}_firstname",
                       "#{table_name}.lastname #{table_name}_lastname",
                       "#{table_name}.login #{table_name}_login",
                       "#{table_name}.mail #{table_name}_mail",
                       "#{table_name}.type #{table_name}_type"] }
          end
        end
      end
    end
  end
end
