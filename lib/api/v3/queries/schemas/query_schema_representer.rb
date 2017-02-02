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
      module Schemas
        class QuerySchemaRepresenter < ::API::Decorators::SchemaRepresenter
          def initialize(represented, form_embedded: false, self_link: nil)
            super(represented,
                  current_user: nil,
                  form_embedded: form_embedded,
                  self_link: self_link)
          end

          schema :id,
                 type: 'Integer',
                 visibility: false

          schema :name,
                 type: 'String',
                 writable: true,
                 min_length: 1,
                 max_length: 255,
                 visibility: false

          schema :user,
                 type: 'User',
                 has_default: true,
                 visibility: false

          schema_with_allowed_link :project,
                                   type: 'Project',
                                   required: false,
                                   writable: true,
                                   visibility: false,
                                   href_callback: ->(*) {
                                     api_v3_paths.available_query_projects
                                   }
          schema :public,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true,
                 visibility: false

          schema :sums,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true,
                 visibility: false

          schema :starred,
                 type: 'Boolean',
                 required: false,
                 writable: true,
                 has_default: true,
                 visibility: false

          schema_with_allowed_collection :columns,
                                         type: '[]QueryColumn',
                                         required: false,
                                         writable: true,
                                         has_default: true,
                                         visibility: false,
                                         values_callback: -> { represented.available_columns },
                                         value_representer: Columns::QueryColumnRepresenter,
                                         link_factory: ->(column) {
                                           converted_name = convert_attribute(column.name)

                                           {
                                             href: api_v3_paths.query_column(converted_name),
                                             title: column.caption
                                           }
                                         }

          schema :filters,
                 type: '[]QueryFilterInstance',
                 required: false,
                 writable: true,
                 has_default: true,
                 visibility: false

          schema_with_allowed_collection :group_by,
                                         type: '[]QueryGroupBy',
                                         required: false,
                                         writable: true,
                                         visibility: false,
                                         values_callback: -> { represented.groupable_columns },
                                         value_representer: GroupBys::QueryGroupByRepresenter,
                                         link_factory: ->(column) {
                                           converted_name = convert_attribute(column.name)

                                           {
                                             href: api_v3_paths.query_group_by(converted_name),
                                             title: column.caption
                                           }
                                         }

          schema_with_allowed_collection :sort_by,
                                         type: '[]QuerySortBy',
                                         required: false,
                                         writable: true,
                                         has_default: true,
                                         visibility: false,
                                         values_callback: -> do
                                           values = represented.sortable_columns.map do |column|
                                             [SortBys::SortByDecorator.new(column.name, 'asc'),
                                              SortBys::SortByDecorator.new(column.name, 'desc')]
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
                 writable: false,
                 visibility: false

          def self.represented_class
            Query
          end

          private

          def convert_attribute(attribute)
            ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
          end
        end
      end
    end
  end
end
