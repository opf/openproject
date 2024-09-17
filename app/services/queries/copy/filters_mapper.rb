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

module Queries::Copy
  class FiltersMapper
    attr_reader :state, :filters, :mappers

    def initialize(state, filters)
      @state = state
      @filters = filters
      @mappers = build_filter_mappers
    end

    ##
    # Returns the mapped filter array for either
    # hash-based APIv3 filters or filter clasess
    def map_filters!
      filters.map do |input|
        if input.is_a?(Hash)
          filter = input.dup.with_indifferent_access
          filter.tap(&method(:map_api_filter_hash))
        else
          map_filter_class(input)
          input
        end
      end
    end

    protected

    ##
    # Maps an API v3 filter hash
    # e.g.,
    # { parent: { operator: '=', values: [1234] } }
    def map_api_filter_hash(filter)
      name = filter.keys.first
      subhash = filter[name]
      ar_name = ::API::Utilities::QueryFiltersNameConverter.to_ar_name(name, refer_to_ids: true)

      subhash["values"] = mapped_values(ar_name, subhash["values"])
    end

    def map_filter_class(filter)
      filter.values = mapped_values(filter.name, filter.values)
    end

    def mapped_values(ar_name, values)
      mapper = mappers[ar_name.to_sym]

      mapper&.call(values) || values
    end

    def build_filter_mappers
      {
        version_id: state_mapper(:version_id_lookup),
        category_id: state_mapper(:category_id_lookup),
        parent: state_mapper(:work_package_id_lookup)
      }
    end

    def state_mapper(lookup_key)
      ->(values) do
        lookup = state.send(lookup_key)
        next unless lookup.is_a?(Hash)

        values.map { |id| (lookup[id.to_i] || id).to_s }
      end
    end
  end
end
