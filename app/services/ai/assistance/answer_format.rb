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

      # The attributes of a proposal, or nil when it does not qualify: a finding needs a text,
      # an area and evidence; a plain proposal needs a valid change.
      def proposal_attributes(raw)
        raw = raw.to_h.stringify_keys
        text = raw["text"].to_s.strip.truncate(MAX_TEXT).presence
        change_set = @proposal_builder.build(raw["changes"])

        if SEVERITIES.include?(raw["severity"]) then finding_attributes(raw, text, change_set)
        elsif change_set then { text:, change_set: }
        end
      end

      private

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

      def finding_attributes(raw, text, change_set)
        evidence = Array(raw["evidence"]).filter_map { |item| item.to_s.strip.presence }
        return if evidence.empty? || text.nil? || AREAS.exclude?(raw["area"])

        { severity: raw["severity"], area: raw["area"], text:, change_set:,
          evidence: evidence.first(MAX_EVIDENCE).map { |item| { "text" => item.truncate(500) } } }
      end
    end
  end
end
