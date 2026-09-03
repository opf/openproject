# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class SearchTool < Base
    class << self
      def pagination_enabled?
        @pagination_enabled || false
      end

      def enable_pagination
        @pagination_enabled = true
      end

      def input_schema(schema = nil)
        if schema && pagination_enabled?
          page = {
            type: "number",
            default: 1,
            description: "Page number for pagination. If no page is defined, the first result set is returned. " \
                         "To get the rest of the results, use a page number of 2 or higher."
          }

          return super(schema.deep_merge({ properties: { page: } }))
        end

        super
      end

      ##
      # Defines a filter for selecting results through input parameters. Only one of filter_proc and filter_class are allowed at
      # the same time. If none is provided, a default where-based filter is created, using name as the filtered attribute name.
      #
      # Filters defined here can later be applied by the tool implementation using #apply_filters.
      #
      # @param name [Symbol] The name of the input parameter used for filtering.
      # @param filter_class [String] Class name of a shared filter implementation to be used to perform filtering,
      #                              inheriting from Queries::Filters::Base.
      # @param operator [String] When using a filter_class, this is the operator that will be used for filtering. Default: "="
      # @param filter_proc [Proc] A callback procedure used for filtering that must accept two arguments:
      #                           The base scope that the filter applies to and the value that's used as a filter input.
      # @example
      #   filter :id
      #
      # @example
      #   filter :name, filter_class: Queries::Projects::Filters::NameFilter, operator: "~"
      #
      # @example
      #   filter :status, filter_proc: ->(scope, value) { scope.where(status_name: value) }
      def filter(name, filter_class: nil, filter_proc: nil, operator: "=")
        if filter_class && filter_proc
          raise ArgumentError, "filter_proc and filter_class are mutually exclusive, please only specify one"
        end

        if filter_class
          filter_proc = ->(scope, value) { filter_class.constantize.create!(operator:, values: Array(value)).apply_to(scope) }
        elsif !filter_proc
          filter_proc = ->(scope, value) { scope.where(name.to_sym => value) }
        end

        filters[name.to_sym] = filter_proc
      end

      def filters
        @filters ||= {}
      end
    end

    private

    def call(page: nil, level_of_detail: "condensed", **filters_and_scope_params)
      scope_params = filters_and_scope_params.slice(*scope_param_names)
      filters = filters_and_scope_params.except(*scope_param_names).reverse_merge(default_filters)
      base_scope(**scope_params).bind do |scope|
        filtered = apply_filters(scope, filters)
        items, total = apply_pagination(filtered, page)

        Success({ items: items.map { |item| apply_lod(format_item(item), level_of_detail:) }, total: })
      end
    end

    def apply_filters(scope, params)
      params.each do |name, value|
        filter_proc = filter_proc_for(name)
        scope = filter_proc.call(scope, value)
      end

      scope
    end

    def filter_proc_for(name)
      self.class.filters[name] || raise(ArgumentError, "Don't know how to handle filter argument called #{name}")
    end

    def apply_pagination(scope, page)
      total = scope.count
      return [scope, total] unless self.class.pagination_enabled?

      page_number = page || 1
      page_size = self.class.page_size

      [scope.offset((page_number - 1) * page_size).limit(page_size), total]
    end

    def apply_lod(item, level_of_detail:)
      return item if level_of_detail == "full" || (condensed_attributes.empty? && condensed_links.empty?)

      hash = item.as_json
      hash.delete_if { |attr| condensed_attributes.exclude?(attr) }
      hash["_links"]&.delete_if { |l| condensed_links.exclude?(l) }
      hash
    end

    ### Methods intended for overwriting in subclasses ###

    # Must return a scope that's used to list items of the given search. The result of this will be passed down
    # to the filtering and pagination.
    def base_scope = raise SubclassResponsibilityError

    # Names of tool call parameters that need to be forwarded to the #base_scope method, if any.
    def scope_param_names = []

    # Hash of default values that filters should assume, if they are not explicitly provided.
    def default_filters = {}

    # Defines formatting of each item returned from the search. Must return something that responds to #as_json.
    def format_item(_item) = raise SubclassResponsibilityError

    # List of attributes that shall be returned in the condensed level-of-detail.
    # If neither #condensed_attributes nor #condensed links are present, only full level-of-detail will be rendered.
    def condensed_attributes = []

    # List of links that shall be returned in the condensed level-of-detail.
    # If neither #condensed_attributes nor #condensed links are present, only full level-of-detail will be rendered.
    def condensed_links = []
  end
end
