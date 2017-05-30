#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# Other than the Roar based representers of the api v3, this
# representer is only responsible for transforming a query's
# attributes into a hash which in turn can be used e.g. to be displayed
# in a url

module API
  module V3
    module Queries
      class QueryParamsRepresenter
        def initialize(query)
          self.query = query
        end

        def to_h
          p = default_hash

          p[:showSums] = 'true' if query.display_sums?
          p[:groupBy] = query.group_by if query.group_by?
          p[:sortBy] = sort_criteria_to_v3 if query.sorted?

          # an empty filter param is also relevant as this would mean to not apply
          # the default filter (status - open)
          p[:filters] = filters_to_v3

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

        def sort_criteria_to_v3
          converted = query.sort_criteria.map { |first, last| [convert_to_v3(first), last] }

          JSON::dump(converted)
        end

        def filters_to_v3
          converted = query.filters.map do |filter|
            { convert_to_v3(filter.name) => { operator: filter.operator, values: filter.values } }
          end

          JSON::dump(converted)
        end

        def convert_to_v3(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute).to_sym
        end

        def default_hash
          { offset: 1, pageSize: Setting.per_page_options_array.first }
        end

        attr_accessor :query
      end
    end
  end
end
