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
      class QueryRepresenter < ::API::Decorators::Single
        self_link

        attr_accessor :results,
                      :params

        def initialize(model,
                       current_user:,
                       results: nil,
                       embed_links: false,
                       params: {})

          self.results = results
          self.params = params

          super(model, current_user: current_user, embed_links: embed_links)
        end

        link :results do
          path = if represented.project
                   api_v3_paths.work_packages_by_project(represented.project.id)
                 else
                   api_v3_paths.work_packages
                 end

          url_query = ::API::V3::Queries::QueryParamsRepresenter
                      .new(represented)
                      .to_h
                      .merge(params.slice(:offset, :pageSize))
          {
            href: [path, url_query.to_query].join('?')
          }
        end

        linked_property :user
        linked_property :project

        property :id
        property :name
        property :filters,
                 exec_context: :decorator,
                 getter: ->(*) {
                   represented.filters.map do |filter|
                     attribute = convert_attribute filter.field
                     {
                       attribute => { operator: filter.operator, values: filter.values }
                     }
                   end
                 }
        property :is_public, getter: -> (*) { is_public }
        property :column_names,
                 exec_context: :decorator,
                 getter: ->(*) {
                   return nil unless represented.column_names
                   represented.column_names.map { |name| convert_attribute name }
                 }
        property :sort_criteria,
                 exec_context: :decorator,
                 getter: ->(*) {
                   return nil unless represented.sort_criteria
                   represented.sort_criteria.map do |attribute, order|
                     [convert_attribute(attribute), order]
                   end
                 }
        property :group_by,
                 exec_context: :decorator,
                 getter: ->(*) {
                   represented.grouped? ? convert_attribute(represented.group_by) : nil
                 },
                 render_nil: true
        property :display_sums, getter: -> (*) { display_sums }
        property :is_starred, getter: -> (*) { starred }

        self.to_eager_load = [:query_menu_item,
                              project: { work_package_custom_fields: :translations }]

        property :results,
                 exec_context: :decorator,
                 render_nil: true,
                 embedded: true,
                 if: ->(*) {
                   results
                 }

        private

        def convert_attribute(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end

        def _type
          'Query'
        end
      end
    end
  end
end
