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
  module AssistantSkills
    module HealthCheck
      # The message the model gets for a health check, and how its answer becomes findings.
      # The prompt itself is data on the skill (instructions and output rules), not code.
      # It reads only what the user who started the run can see: the job runs as that user.
      class Review
        AREAS = %w[content status relations tree].freeze

        attr_reader :run

        def initialize(run)
          @run = run
        end

        def work_package
          run.work_package
        end

        def lock_version
          @lock_version ||= work_package.reload.lock_version
        end

        def schema
          {
            type: "object",
            additionalProperties: false,
            required: %w[findings],
            properties: {
              findings: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  required: %w[severity area text evidence changes],
                  properties: {
                    severity: { type: "string", enum: AI::AssistantRunFinding.severities.keys },
                    area: { type: "string", enum: AREAS },
                    text: { type: "string" },
                    evidence: { type: "array", items: { type: "string" } },
                    changes: proposal_builder.schema
                  }
                }
              }
            }
          }
        end

        def user_message
          AI::Assistance::WorkPackageContext.new(work_package:, user: run.user).to_h.merge(
            rule_findings: run.findings.rule.map(&:text),
            change_options: change_options.for_prompt
          ).to_json
        end

        # Attributes for an AI finding, or nil when the answer does not qualify.
        def finding_attributes(raw)
          raw = raw.to_h.stringify_keys
          evidence = Array(raw["evidence"]).filter_map { |text| text.to_s.strip.presence }
          return if evidence.empty? || raw["text"].to_s.strip.empty?
          return unless AI::AssistantRunFinding.severities.key?(raw["severity"]) && AREAS.include?(raw["area"])

          {
            severity: raw["severity"],
            area: raw["area"],
            text: raw["text"].to_s.strip.truncate(1_000),
            evidence: evidence.first(5).map { |text| { "text" => text.truncate(500) } },
            change_set: proposal_builder.build(raw["changes"])
          }
        end

        private

        def change_options
          @change_options ||= AI::Assistance::ChangeOptions.new(keys: run.skill.changeable_attributes, work_package:, user: run.user)
        end

        def proposal_builder
          @proposal_builder ||= AI::Assistance::ProposalBuilder.new(change_options)
        end
      end
    end
  end
end
