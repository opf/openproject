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

# Other than the Roar based representers of the api v3, this
# representer is only responsible for transforming a query's
# attributes into a hash which in turn can be used e.g. to be displayed
# in a url

module API
  module V3
    module Queries
      class QueryParamsRepresenter < API::Decorators::QueryParamsRepresenter
        ##
        # To json hash outputs the hash to be parsed to the frontend http
        # which contains a reference to the columns array as columns[].
        # This will match the Rails +to_query+ output
        def to_json(*_args)
          to_h(column_key: :"columns[]").to_json
        end

        def to_h(column_key: :columns)
          p = super

          p[:includeSubprojects] = query.include_subprojects
          p[:showHierarchies] = query.show_hierarchies
          p[:showSums] = query.display_sums?
          p[:groupBy] = query.group_by if query.group_by?
          p[column_key] = columns_to_v3 unless query.has_default_columns?

          p
        end

        def self_link
          if query.project
            api_v3_paths.work_packages_by_project(query.project.id)
          else
            api_v3_paths.work_packages
          end
        end

        private

        def orders_to_v3
          converted = query.sort_criteria.map { |first, last| [convert_to_v3(first), last] }

          JSON::dump(converted)
        end

        def columns_to_v3
          query.column_names.map { |name| convert_to_v3(name) }
        end

        attr_accessor :query
      end
    end
  end
end
