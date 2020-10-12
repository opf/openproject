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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Queries
      module Schemas
        class QuerySchemaRepresenter < ::API::Decorators::SchemaRepresenter
          def initialize(represented, self_link = nil, current_user: nil, form_embedded: false)
            super(represented,
                  self_link,
                  current_user: current_user,
                  form_embedded: form_embedded)
          end

          def self.filters_schema
            ->(*) do
              {
                'type': '[]QueryFilterInstance',
                'name': Query.human_attribute_name('filters'),
                'required': false,
                'writable': true,
                'hasDefault': true,
                '_links': {
                  'allowedValuesSchemas': {
                    'href': filter_instance_schemas_href
                  }
                }
              }
            end
          end

          schema :id,
                 type: 'Integer'

          schema :name,
                 type: 'String',
                 writable: true,
                 min_length: 1,
                 max_length: 255

          schema :created_at,
                 type: 'DateTime'

          schema :updated_at,
                 type: 'DateTime'

          schema :user,
                 type: 'User',
                 has_default: true

          schema_with_allowed_link :project,
                                   type: 'Project',
                                   required: false,
                                   writable: true,
                                   href_callback: ->(*) {
                                     api_v3_paths.query_available_projects
                                   }
          schema :public,
                 type: 'Boolean',
                 required: false,
                 writable: -> do
                   current_user.allowed_to?(:manage_public_queries,
                                            represented.project,
                                            global: represented.project.nil?)
                 end,
                 has_default: true

          schema :sums,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true

          schema :timeline_visible,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true

          schema :timeline_zoom_level,
                 type: 'String',
                 required: false,
                 writable: true,
                 has_default: true

          schema :timeline_labels,
                 type: 'QueryTimelineLabels',
                 required: false,
                 writable: true,
                 has_default: true

          schema :highlighting_mode,
                 type: 'String',
                 required: false,
                 writable: true,
                 has_default: true

          schema :display_representation,
                 type: 'String',
                 required: false,
                 writable: true,
                 has_default: true

          schema :show_hierarchies,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true

          schema :starred,
                 type: 'Boolean',
                 required: false,
                 writable: false,
                 has_default: true

          schema :hidden,
                 type: 'Boolean',
                 required: true,
                 writable: true,
                 has_default: true

          schema :ordered_work_packages,
                 type: 'QueryOrder',
                 required: false,
                 writable: true,
                 has_default: true

          schema_with_allowed_collection :columns,
                                         type: '[]QueryColumn',
                                         required: false,
                                         writable: true,
                                         has_default: true,
                                         values_callback: -> { represented.available_columns },
                                         value_representer: ->(column) {
                                           Columns::QueryColumnsFactory.representer(column)
                                         },
                                         link_factory: ->(column) {
                                           converted_name = convert_attribute(column.name)

                                           {
                                             href: api_v3_paths.query_column(converted_name),
                                             title: column.caption
                                           }
                                         }

          schema_property :filters,
                          filters_schema,
                          true,
                          false,
                          true,
                          :filters,
                          :filters

          schema_with_allowed_collection :group_by,
                                         type: '[]QueryGroupBy',
                                         required: false,
                                         writable: true,
                                         values_callback: -> { represented.groupable_columns },
                                         value_representer: GroupBys::QueryGroupByRepresenter,
                                         link_factory: ->(column) {
                                           converted_name = convert_attribute(column.name)

                                           {
                                             href: api_v3_paths.query_group_by(converted_name),
                                             title: column.caption
                                           }
                                         }

          schema_with_allowed_collection :highlighted_attributes,
                                         type: '[]QueryColumn',
                                         required: false,
                                         writable: true,
                                         has_default: true,
                                         values_callback: -> { represented.available_highlighting_columns },
                                         value_representer: ->(column) {
                                           Columns::QueryColumnsFactory.representer(column)
                                         },
                                         link_factory: ->(column) {
                                           converted_name = convert_attribute(column.name)

                                           {
                                             href: api_v3_paths.query_column(converted_name),
                                             id: converted_name,
                                             title: column.caption
                                           }
                                         }

          schema_with_allowed_collection :sort_by,
                                         type: '[]QuerySortBy',
                                         required: false,
                                         writable: true,
                                         has_default: true,
                                         values_callback: -> do
                                           values = represented.sortable_columns.map do |column|
                                             [SortBys::SortByDecorator.new(column, 'asc'),
                                              SortBys::SortByDecorator.new(column, 'desc')]
                                           end

                                           values.flatten
                                         end,
                                         value_representer: SortBys::QuerySortByRepresenter,
                                         link_factory: ->(sort_by) {
                                           name = sort_by.converted_name
                                           direction = sort_by.direction_name
                                           {
                                             href: api_v3_paths.query_sort_by(name, direction),
                                             title: sort_by.name
                                           }
                                         }

          schema :results,
                 type: 'WorkPackageCollection',
                 required: false,
                 writable: false

          property :filters_schemas,
                   embedded: true,
                   exec_context: :decorator

          def self.represented_class
            Query
          end

          def convert_attribute(attribute)
            ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
          end

          def filters_schemas
            # TODO: The RelatableFilter is not supported by the schema dependencies yet
            filters = represented
                      .available_filters
                      .reject { |f| f.is_a?(::Queries::WorkPackages::Filter::RelatableFilter) }

            QueryFilterInstanceSchemaCollectionRepresenter.new(filters,
                                                               filter_instance_schemas_href,
                                                               form_embedded: form_embedded,
                                                               current_user: current_user)
          end

          def filter_instance_schemas_href
            if represented.project
              api_v3_paths.query_project_filter_instance_schemas(represented.project.id)
            else
              api_v3_paths.query_filter_instance_schemas
            end
          end
        end
      end
    end
  end
end
