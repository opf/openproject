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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Queries
      class QueryPayloadRepresenter < ::API::Decorators::Single
        prepend QuerySerialization

        links :columns do
          represented.columns.map do |column|
            { href: api_v3_paths.query_column(convert_attribute(column.name)) }
          end
        end

        link :groupBy do
          column = represented.group_by_column

          if column
            { href: api_v3_paths.query_group_by(convert_attribute(column.name)) }
          else
            { href: nil }
          end
        end

        links :sortBy do
          represented.sort_criteria.map do |column, dir|
            name = ::API::Utilities::PropertyNameConverter.from_ar_name column

            { href: api_v3_paths.query_sort_by(name, dir) }
          end
        end

        linked_property :project

        property :name
        property :filters,
                 exec_context: :decorator,
                 getter: ->(*) { trimmed_filters filters }

        property :display_sums, as: :sums
        property :is_public, as: :public

        private

        ##
        # Uses the a normal query's filter representation and removes the bits
        # we don't want for a payload.
        def trimmed_filters(filters)
          filters.map(&:to_hash).map { |v| trim_links v }
        end

        def trim_links(value)
          if value.is_a? ::Hash
            value.except("_type", "name", "title", "schema").map_values { |v| trim_links v }
          elsif value.is_a? Array
            value.map { |v| trim_links v }
          else
            value
          end
        end

        def convert_attribute(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end
      end
    end
  end
end
