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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  module Completions
    class Request
      include ActiveModel::Validations

      MAX_MESSAGES = 200
      MAX_TOOLS = 64
      MAX_CHARACTERS = 400_000
      TOOL_NAME = /\A[a-zA-Z0-9_-]{1,64}\z/
      ROLES = %w[user assistant tool].freeze

      Message = Data.define(:role, :content, :tool_calls, :tool_call_id, :thinking)
      ToolCall = Data.define(:id, :name, :arguments)
      Tool = Data.define(:name, :description, :input_schema)

      attr_reader :system, :messages, :tools

      validates :messages, length: { minimum: 1, maximum: MAX_MESSAGES }
      validates :tools, length: { maximum: MAX_TOOLS }
      validate :validate_messages, :validate_tools, :validate_size

      # @param params [Hash] the request body, with camelCase keys as API v3 uses them
      def self.from_params(params)
        params = params.to_h.deep_stringify_keys
        new(system: params["system"].to_s,
            messages: Array(params["messages"]).grep(Hash).map { |raw| message_from(raw) },
            tools: Array(params["tools"]).grep(Hash).map { |raw| tool_from(raw) })
      end

      def self.message_from(raw)
        Message.new(role: raw["role"].to_s,
                    content: raw["content"].to_s,
                    tool_calls: Array(raw["toolCalls"]).grep(Hash).map { |call| tool_call_from(call) },
                    tool_call_id: raw["toolCallId"].presence,
                    thinking: raw["thinking"].presence&.slice("text", "signature"))
      end

      def self.tool_call_from(call)
        ToolCall.new(id: call["id"].to_s, name: call["name"].to_s, arguments: call["arguments"].to_h)
      end

      def self.tool_from(raw)
        Tool.new(name: raw["name"].to_s,
                 description: raw["description"].to_s,
                 input_schema: raw["inputSchema"].presence || { "type" => "object", "properties" => {} })
      end

      def initialize(system:, messages:, tools:)
        @system = system
        @messages = messages
        @tools = tools
      end

      private

      def validate_messages
        errors.add(:messages, :unknown_role, roles: ROLES.join(", ")) if unknown_role?
        errors.add(:messages, :tool_result_without_id) if tool_result_without_id?
        errors.add(:messages, :assistant_last) if messages.last&.role == "assistant"
      end

      def validate_tools
        errors.add(:tools, :invalid_name, pattern: TOOL_NAME.source) if tools.any? { |tool| !TOOL_NAME.match?(tool.name) }
        errors.add(:tools, :duplicate_name) if tools.map(&:name).uniq.size != tools.size
      end

      def validate_size
        errors.add(:base, :too_large, count: MAX_CHARACTERS) if characters > MAX_CHARACTERS
      end

      def unknown_role? = messages.any? { |message| ROLES.exclude?(message.role) }

      def tool_result_without_id? = messages.any? { |message| message.role == "tool" && message.tool_call_id.blank? }

      def characters
        system.size + messages.sum { |message| message_characters(message) } +
          tools.sum { |tool| tool.description.size + tool.input_schema.to_json.size }
      end

      def message_characters(message)
        message.content.size + message.tool_calls.sum { |call| call.arguments.to_json.size }
      end
    end
  end
end
