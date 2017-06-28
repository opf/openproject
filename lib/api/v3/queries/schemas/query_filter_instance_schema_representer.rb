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

require 'queries/operators'

module API
  module V3
    module Queries
      module Schemas
        class QueryFilterInstanceSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          include API::Utilities::RepresenterToJsonCache

          schema :name,
                 type: 'String',
                 writable: false,
                 has_default: true,
                 required: true,
                 visibility: false

          def self.filter_representer
            ::API::V3::Queries::Filters::QueryFilterRepresenter
          end

          def self.filter_link_factory
            ->(*) do
              {
                href: api_v3_paths.query_filter(convert_attribute(filter.name)),
                title: filter.human_name
              }
            end
          end

          schema_with_allowed_collection :filter,
                                         type: 'QueryFilter',
                                         required: true,
                                         writable: true,
                                         visibility: false,
                                         values_callback: -> {
                                           [filter]
                                         },
                                         value_representer: filter_representer,
                                         link_factory: filter_link_factory

          def self.operator_representer
            ::API::V3::Queries::Operators::QueryOperatorRepresenter
          end

          def self.operator_link_factory
            ->(operator) do
              {
                href: api_v3_paths.query_operator(operator.to_query),
                title: operator.human_name
              }
            end
          end

          schema_with_allowed_collection :operator,
                                         type: 'QueryOperator',
                                         writable: true,
                                         has_default: false,
                                         required: true,
                                         visibility: false,
                                         values_callback: -> {
                                           filter.available_operators
                                         },
                                         value_representer: operator_representer,
                                         link_factory: operator_link_factory

          # While this is not actually the represented class,
          # this is what the superclass expects in order to have the
          # right i18n
          def self.represented_class
            WorkPackage
          end

          alias :filter :represented

          def _type
            'QueryFilterInstanceSchema'
          end

          def _name
            convert_attribute(filter.name)
          end

          def _dependencies
            [
              ::API::V3::Schemas::SchemaDependencyRepresenter.new(dependencies,
                                                                  'operator',
                                                                  current_user: current_user)
            ]
          end

          def convert_attribute(attribute)
            ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
          end

          def dependencies
            @dependencies ||= filter.available_operators.each_with_object({}) do |operator, hash|
              path = api_v3_paths.query_operator(operator.to_query)
              value = FilterDependencyRepresenterFactory.create(filter,
                                                                operator,
                                                                form_embedded: form_embedded)

              hash[path] = value
            end
          end

          def json_cacheable?
            dependencies
              .values
              .all?(&:json_cacheable?)
          end

          def json_cache_key
            dependencies
              .values
              .flat_map(&:json_cache_key)
              .uniq + [form_embedded, filter.name]
          end
        end
      end
    end
  end
end
