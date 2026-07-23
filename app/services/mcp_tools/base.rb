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
  class Base
    RESPONSE_FORMATS = %i[full content_only structured_only].freeze

    class << self
      def qualified_name
        "tools/#{name}"
      end

      def page_size
        40
      end

      def default_title(title = nil)
        @default_title = title if title.present?

        @default_title
      end

      def default_description(description = nil)
        @default_description = description if description.present?

        @default_description
      end

      def name(name = nil)
        @name = name if name.present?

        @name
      end

      def pagination_enabled?
        @pagination_enabled || false
      end

      def enable_pagination
        @pagination_enabled = true
      end

      def input_schema(schema = nil)
        if schema.present?
          if pagination_enabled?
            page = {
              type: "number",
              default: 1,
              description: "Page number for pagination. If no page is defined, the first result set is returned. " \
                           "To get the rest of the results, use a page number of 2 or higher."
            }

            @input_schema = schema.deep_merge({ properties: { page: } })
          else
            @input_schema = schema
          end
        end

        @input_schema
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

      def output_filter(filter_class)
        output_filters << filter_class
      end

      def output_filters
        @output_filters ||= []
      end

      def annotations(read_only:, idempotent:, destructive:)
        @annotations = {
          read_only_hint: read_only,
          destructive_hint: destructive,
          idempotent_hint: idempotent,
          open_world_hint: false
        }
      end

      def read_annotations
        # Initialize default annotations, if none are present
        annotations(read_only: false, destructive: true, idempotent: false) if @annotations.nil?

        @annotations
      end

      def tool
        config = McpConfiguration.find_by(identifier: qualified_name)
        return nil if config.nil?

        implementation = self
        MCP::Tool.define(
          name:,
          title: config.title,
          description: config.description,
          input_schema:,
          annotations: read_annotations
        ) do |server_context: {}, **opts|
          implementation.new(server_context:, tool_context: self).handle_request(**opts)
        end
      end
    end

    def initialize(server_context:, tool_context:)
      @server_context = server_context
      @tool_context = tool_context
    end

    def handle_request(**)
      result = call(**)

      format_response(result)
    end

    private

    # Intended to be implemented by subclasses. It should return a structured result (e.g. a Hash or Array).
    def call(**)
      raise NotImplemented, "#{self.class} needs to implement #call method"
    end

    def format_response(result)
      result = self.class.output_filters.inject(JSON.parse(result.to_json)) { |r, f| f.filter(r) }
      plain = render_plain_content? ? format_content(result) : []
      structured_content = render_structured_content? ? format_structured_content(result) : nil
      MCP::Tool::Response.new(plain, **{ structured_content: }.compact)
    end

    def format_content(result)
      [{ type: "text", text: result.to_json }]
    end

    def format_structured_content(result)
      # performing a useless JSON roundtrip to ensure that our representers get converted into proper Ruby hashes,
      # because the mcp gem performs strict type checks on the structured content
      JSON.parse(result.to_json)
    end

    def current_user
      @server_context[:current_user]
    end

    def render_plain_content?
      %i[full content_only].include?(Setting.mcp_tool_response_format)
    end

    def render_structured_content?
      %i[full structured_only].include?(Setting.mcp_tool_response_format)
    end

    # Usable by tool implementations. Takes a scope and filters it according to the passed params.
    # Filtering happens based on the filters defined for the tool, see .filter.
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
      return scope unless self.class.pagination_enabled?

      page_number = page || 1
      page_size = self.class.page_size

      scope.offset((page_number - 1) * page_size).limit(page_size)
    end
  end
end
