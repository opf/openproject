#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Queries
  class CopyService < ::BaseServices::Copy
    protected

    def copy_dependencies
      [
        ::Queries::Copy::MenuItemDependentService,
        ::Queries::Copy::OrderedWorkPackagesDependentService
      ]
    end

    def initialize_copy(source, params)
      new_query = ::Query.new source.attributes.dup.except(*skipped_attributes)
      new_query.sort_criteria = source.sort_criteria if source.sort_criteria
      new_query.project = state.project || source.project

      map_filters new_query

      ServiceResult.new(success: new_query.save, result: new_query)
    end

    def map_filters(query)
      mappers = filter_mappers

      query.filters.each do |filter|
        mapper = mappers[filter.name.to_sym]

        mapper&.call filter
      end
    end

    def filter_mappers
      {
        version_id: method(:map_version_filter),
        category_id: method(:map_category_filter)
      }
    end

    def map_version_filter(filter)
      return unless state.version_id_lookup

      filter.values = filter.values.map { |id| state.version_id_lookup[id.to_i] || id }
    end

    def map_category_filter(filter)
      return unless state.category_id_lookup

      filter.values = filter.values.map { |id| state.category_id_lookup[id.to_i] || id }
    end

    def skipped_attributes
      %w[id created_at updated_at project_id sort_criteria]
    end
  end
end
