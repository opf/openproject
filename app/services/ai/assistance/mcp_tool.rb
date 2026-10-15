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

module AI
  module Assistance
    # A read-only MCP tool (app/services/mcp_tools) offered to the model in a chat answer. It runs
    # in-process as the chat user, so the tool's own visibility rules apply. AI::Assistance::ToolCalls
    # counts, logs and limits the calls of one answer.
    class McpTool < RubyLLM::Tool
      EXCLUDED = %w[search_time_entries].freeze

      class << self
        def read_only_classes
          McpTools.all.select { |tool| tool.read_annotations[:read_only_hint] }
                      .reject { |tool| EXCLUDED.include?(tool.name) }
        end

        def for(mcp_class, user:, calls:)
          schema = parameters_for(mcp_class)
          Class.new(self) do
            description mcp_class.default_description.to_s
            params schema
          end.new(mcp_class, user:, calls:)
        end

        private

        def parameters_for(mcp_class)
          schema = { "type" => "object" }.merge((mcp_class.input_schema || {}).deep_stringify_keys)
          schema["properties"] ||= {}
          schema
        end
      end

      def initialize(mcp_class, user:, calls:)
        super()
        @mcp_class = mcp_class
        @user = user
        @calls = calls
      end

      delegate :name, to: :@mcp_class

      def execute(**args)
        args = without_disallowed_nulls(args)
        @calls.run(name, args) do
          text_of(@mcp_class.new(server_context: { current_user: @user }, tool_context: nil).handle_request(**args))
        end
      end

      private

      # Some models send null for every argument they do not need. Only arguments whose schema
      # allows null keep it (assigned_to_id: null means "unassigned").
      def without_disallowed_nulls(args)
        properties = (@mcp_class.input_schema || {})[:properties] || {}
        args.reject do |key, value|
          value.nil? && Array(properties.dig(key, :type)).map(&:to_s).exclude?("null")
        end
      end

      # Text items as they are, embedded resources by their text, and the structured content when
      # the response format is structured_only.
      def text_of(response)
        hash = response.to_h
        text = Array(hash[:content]).map { |item| item[:text] || item.dig(:resource, :text) || item.to_json }.join("\n")
        text.presence || hash[:structuredContent].to_json
      end
    end
  end
end
