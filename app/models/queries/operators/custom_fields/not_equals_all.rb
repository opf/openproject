#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Queries::Operators
  module CustomFields
    class NotEqualsAll < ::Queries::Operators::NotEquals
      def self.sql_for_customized(values, custom_field_id, customized_type, customized_id_join_field)
        # code expects strings (e.g. for quoting), but ints would work as well: unify them here
        values = values.map(&:to_s)
        cv_table = CustomValue.table_name

        if values.present?
          sql = values.map do |val|
            "NOT EXISTS (SELECT 1 FROM #{cv_table} WHERE customized_type = '#{connection.quote_string(customized_type)}' " \
              "AND custom_field_id = #{custom_field_id} " \
              "AND customized_id = #{customized_id_join_field} " \
              "AND value ='#{connection.quote_string(val)}')"
          end

          sql.join(' AND ')
        else
          # empty set of allowed values produces no result
          '0=1'
        end
      end
    end
  end
end
