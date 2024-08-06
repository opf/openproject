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
  module Decorators
    class QueryParamsRepresenter
      def initialize(query)
        self.query = query
      end

      ##
      # To json hash outputs the hash to be parsed to the frontend http
      # which contains a reference to the columns array as columns[].
      # This will match the Rails +to_query+ output
      def to_json(*_args)
        to_h.to_json
      end

      ##
      # Output as query params used for directly using in URL queries.
      # Outputs columns[]=A,columns[]=B due to Rails query output.
      def to_url_query(merge_params: {})
        to_h
          .merge(merge_params.symbolize_keys)
          .to_query
      end

      def to_h(*_args)
        p = default_hash

        p[:sortBy] = orders_to_v3 if query.ordered?

        # an empty filter param is also relevant as this would mean to not apply
        # the default filter (status - open)
        p[:filters] = filters_to_v3

        p
      end

      private

      def orders_to_v3
        converted = query.orders.map { |order| [convert_to_v3(order.attribute), order.direction] }

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
