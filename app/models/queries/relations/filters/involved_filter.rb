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

module Queries
  module Relations
    module Filters
      ##
      # Filters relations by work package ID in either `from` or `to` position of a relation.
      # For instance:
      #   Given relations [{ from_id: 3, to_id: 7 }, { from_id: 8, to_id: 3}]
      #   filtering by involved=3 would yield both these relations.
      class InvolvedFilter < ::Queries::Relations::Filters::RelationFilter
        include ::Queries::Relations::Filters::VisibilityChecking

        def type
          :integer
        end

        def self.key
          :involved
        end

        private

        def visibility_checked_sql(operator_string, values, visible_sql)
          concatenation = if operator == "="
                            "OR"
                          else
                            "AND"
                          end

          sql = <<~SQL.squish
            (from_id #{operator_string} (?) AND to_id IN (#{visible_sql}))
             #{concatenation} (to_id #{operator_string} (?) AND from_id IN (#{visible_sql}))
          SQL

          [sql, values, values]
        end
      end
    end
  end
end
