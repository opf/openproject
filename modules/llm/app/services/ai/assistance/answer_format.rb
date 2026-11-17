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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module Assistance
    # The one answer format of every turn: text, and proposals. A proposal is a finding (a
    # problem, with a severity, an area and evidence) or a plain change that the user asked
    # for. Which kind an answer holds is up to the skill's instructions.
    class AnswerFormat
      SEVERITIES = %w[high medium low].freeze
      AREAS = %w[content status relations tree pull_requests].freeze
      NONE = "none"
      MAX_TEXT = 1_000
      MAX_EVIDENCE = 5
      CHANGE_AREAS = { "subject" => "content", "description" => "content", "comment" => "content",
                       "status" => "status" }.freeze
      FIELD_ORDER = (ChangeOptions::ATTRIBUTE_KEYS + ["comment"]).freeze

      def initialize(proposal_builder)
        @proposal_builder = proposal_builder
      end

      def schema
        {
          type: "object",
          additionalProperties: false,
          required: %w[answer proposals],
          properties: { answer: { type: "string" }, proposals: { type: "array", items: proposal_schema } }
        }
      end

      # The attributes of a proposal and nil, or nil and the reason why it does not qualify:
      # a finding needs a text and evidence; a plain proposal needs a valid change.
      def evaluate(raw)
        raw = raw.to_h.stringify_keys
        text = raw["text"].to_s.strip.truncate(MAX_TEXT).presence
        change_set = @proposal_builder.build(raw["changes"])

        if SEVERITIES.include?(raw["severity"]) then finding(raw, text, change_set)
        elsif change_set then [{ text:, change_set: }, nil]
        else [nil, "no valid change"]
        end
      end

      # A fixed order within a severity, so that runs with the same proposals list them the same
      # way: by the first changed field, then by area, then in the model's order.
      def sort(proposals_attributes)
        proposals_attributes.sort_by.with_index { |attributes, index| [*sort_key(attributes), index] }
      end

      private

      def sort_key(attributes)
        keys = Array(attributes[:change_set]&.dig("actions")).pluck("key")
        [keys.filter_map { |key| FIELD_ORDER.index(key) }.min || FIELD_ORDER.size,
         AREAS.index(attributes[:area]) || AREAS.size]
      end

      def proposal_schema
        {
          type: "object",
          additionalProperties: false,
          required: %w[text severity area evidence changes],
          properties: {
            text: { type: "string" },
            severity: { type: "string", enum: SEVERITIES + [NONE] },
            area: { type: "string", enum: AREAS + [NONE] },
            evidence: { type: "array", items: { type: "string" } },
            changes: @proposal_builder.schema
          }
        }
      end

      def finding(raw, text, change_set)
        evidence = Array(raw["evidence"]).filter_map { |item| item.to_s.strip.presence }
        return [nil, "no evidence"] if evidence.empty?
        return [nil, "no text"] if text.nil?

        [{ severity: raw["severity"], area: area_for(raw["area"], change_set), text:, change_set:,
           evidence: evidence.first(MAX_EVIDENCE).map { |item| { "text" => item.truncate(500) } } }, nil]
      end

      # The changed fields name the area. Models label it inconsistently: some use "none" for
      # findings, or one area for all of them.
      def area_for(area, change_set)
        keys = Array(change_set&.dig("actions")).pluck("key")
        CHANGE_AREAS.values_at(*keys).compact.first || (area if AREAS.include?(area))
      end
    end
  end
end
