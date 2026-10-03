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
    include Dry::Monads::Result(String)

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

      def input_schema(schema = nil)
        @input_schema = schema if schema

        @input_schema
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

      def tool(title:, description:)
        implementation = self
        MCP::Tool.define(
          name:,
          title:,
          description:,
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

      response = result.either(
        ->(r) { r },
        ->(error) { { error: } }
      )

      format_response(response)
    end

    private

    # Intended to be implemented by subclasses. It should return a success monad with structured result (e.g. a Hash or Array)
    # or a failure monad with an error message.
    def call(**)
      raise SubclassResponsibilityError, "#{self.class} needs to implement #call method"
    end

    def format_response(response)
      response = self.class.output_filters.each_with_object(response.as_json) { |f, r| f.filter(r) }
      plain = render_plain_content? ? format_content(response) : []
      structured_content = render_structured_content? ? format_structured_content(response) : nil
      MCP::Tool::Response.new(plain, **{ structured_content: }.compact)
    end

    def format_content(response)
      [{ type: "text", text: response.to_json }]
    end

    def format_structured_content(response)
      # Ensure that our representers get converted into proper Ruby hashes,
      # because the mcp gem performs strict type checks on the structured content
      response.as_json
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
  end
end
