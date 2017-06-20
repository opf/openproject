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

        include API::Decorators::LinkedResource

        associated_resource :project,
                            setter: ->(fragment:, **) {
                              id = id_from_href "projects", fragment['href']

                              id = if id.to_i.nonzero?
                                     id # return numerical ID
                                   else
                                     Project.where(identifier: id).pluck(:id).first # lookup Project by identifier
                                   end

                              represented.project_id = id if id
                            },
                            skip_link: ->(*) {
                              false
                            },
                            skip_render: ->(*) {
                              represented.project.nil?
                            }

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

        link :star do
          next if represented.starred || !allowed_to?(:star)

          {
            href: api_v3_paths.query_star(represented.id),
            method: :patch
          }
        end

        link :unstar do
          next unless represented.starred && allowed_to?(:unstar)

          {
            href: api_v3_paths.query_unstar(represented.id),
            method: :patch
          }
        end

        link :schema do
          href = if represented.project
                   api_v3_paths.query_project_schema(represented.project.identifier)
                 else
                   api_v3_paths.query_schema
                 end
          {
            href: href
          }
        end

        link :update do
          href = if represented.new_record?
                   api_v3_paths.create_query_form
                 else
                   api_v3_paths.query_form(represented.id)
                 end

          {
            href: href,
            method: :post
          }
        end

        link :updateImmediately do
          next unless represented.new_record? && allowed_to?(:create) ||
                      represented.persisted? && allowed_to?(:update)
          {
            href: api_v3_paths.query(represented.id),
            method: :patch
          }
        end

        link :delete do
          next if represented.new_record? ||
                  !allowed_to?(:destroy)

          {
            href: api_v3_paths.query(represented.id),
            method: :delete
          }
        end

        associated_resource :user

        resources :sortBy,
                  getter: ->(*) {
                    return unless represented.sort_criteria

                    map_with_sort_by_as_decorated(represented.sort_criteria_columns) do |sort_by|
                      ::API::V3::Queries::SortBys::QuerySortByRepresenter.new(sort_by)
                    end
                  },
                  setter: ->(fragment:, **) {
                    criteria = Array(fragment).map do |sort_by|
                      column_direction_from_href(sort_by)
                    end

                    represented.sort_criteria = criteria.compact if fragment
                  },
                  link: ->(*) {
                    map_with_sort_by_as_decorated(represented.sort_criteria_columns) do |sort_by|
                      {
                        href: api_v3_paths.query_sort_by(sort_by.converted_name, sort_by.direction_name),
                        title: sort_by.name
                      }
                    end
                  }

        resource :groupBy,
                 getter: ->(*) {
                   return unless represented.grouped?

                   column = represented.group_by_column

                   ::API::V3::Queries::GroupBys::QueryGroupByRepresenter.new(column)
                 },
                 setter: ->(fragment:, **) {
                   attr = id_from_href "queries/group_bys", fragment['href']

                   represented.group_by =
                     if attr.nil?
                       nil
                     else
                       ::API::Utilities::PropertyNameConverter.to_ar_name(attr, context: WorkPackage.new)
                     end
                 },
                 link: ->(*) {
                   column = represented.group_by_column

                   if column
                     {
                       href: api_v3_paths.query_group_by(convert_attribute(column.name)),
                       title: column.caption
                     }
                   else
                     {
                       href: nil,
                       title: nil
                     }
                   end
                 }

        resources :columns,
                  getter: ->(*) {
                    represented.columns.map do |column|
                      ::API::V3::Queries::Columns::QueryColumnsFactory.create(column)
                    end
                  },
                  setter: ->(fragment:, **) {
                    columns = Array(fragment).map do |column|
                      name = id_from_href "queries/columns", column['href']

                      ::API::Utilities::PropertyNameConverter.to_ar_name(name, context: WorkPackage.new) if name
                    end

                    represented.column_names = columns.map(&:to_sym).compact if fragment
                  },
                  link: ->(*) {
                    represented.columns.map do |column|
                      {
                        href: api_v3_paths.query_column(convert_attribute(column.name)),
                        title: column.caption
                      }
                    end
                  }

        property :starred,
                 writeable: true

        property :results,
                 exec_context: :decorator,
                 render_nil: true,
                 embedded: true,
                 if: ->(*) {
                   results
                 }

        property :id,
                 writeable: false
        property :name
        property :filters,
                 exec_context: :decorator

        property :display_sums, as: :sums
        property :is_public, as: :public

        # Timeline properties
        property :timeline_visible

        property :show_hierarchies

        property :timeline_zoom_level

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

        self.to_eager_load = [:query_menu_item,
                              :user,
                              project: :work_package_custom_fields]

        def _type
          'Query'
        end

        def filters
          represented.filters.map do |filter|
            ::API::V3::Queries::Filters::QueryFilterInstanceRepresenter
              .new(filter)
          end
        end

        def filters=(filters_hash)
          represented.filters = []

          filters_hash.each do |filter_attributes|
            name = get_filter_name filter_attributes

            filter = represented.filter_for name
            if filter
              filter_representer = ::API::V3::Queries::Filters::QueryFilterInstanceRepresenter.new(filter)

              filter = filter_representer.from_hash filter_attributes
              represented.filters << filter
            else
              raise API::Errors::InvalidRequestBody, "Could not read filter from: #{filter_attributes}"
            end
          end
        end

        private

        def allowed_to?(action)
          @policy ||= QueryPolicy.new(current_user)

          @policy.allowed?(represented, action)
        end

        def self_v3_path(*_args)
          if represented.new_record? && represented.project
            api_v3_paths.query_project_default(represented.project.id)
          elsif represented.new_record?
            api_v3_paths.query_default
          else
            super
          end
        end

        def convert_attribute(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end

        def get_filter_name(filter_attributes)
          href = filter_attributes.dig("_links", "filter", "href")
          id = id_from_href "queries/filters", href

          ::API::Utilities::QueryFiltersNameConverter.to_ar_name id, refer_to_ids: true if id
        end

        def id_from_href(expected_namespace, href)
          return nil if href.blank?

          ::API::Utilities::ResourceLinkParser.parse_id(
            href,
            property: (expected_namespace && expected_namespace.split("/").last) || "filter_value",
            expected_version: "3",
            expected_namespace: expected_namespace
          )
        end

        def column_direction_from_href(sort_by)
          if id = id_from_href("queries/sort_bys", sort_by['href'])
            column, direction = id.split("-") # e.g. ["start_date", "desc"]

            if column && direction
              column = ::API::Utilities::PropertyNameConverter.to_ar_name(column, context: WorkPackage.new)
              direction = nil unless ["asc", "desc"].include? direction

              [column, direction]
            end
          end
        end

        def map_with_sort_by_as_decorated(sort_criteria)
          sort_criteria.reject { |c, o| c.nil? || o.nil? }.map do |column, order|
            decorated = ::API::V3::Queries::SortBys::SortByDecorator.new(column, order)

            yield decorated
          end
        end
      end
    end
  end
end
