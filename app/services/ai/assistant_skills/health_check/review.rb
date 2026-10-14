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
      # The message for the first answer of a skill with the built-in checks: the work
      # package context, the rule findings and the values the model may propose. The prompt
      # itself is data on the skill (instructions and output rules), not code. It reads only
      # what the user can see: the job runs as that user.
      class Review
        attr_reader :skill, :work_package, :user, :rule_findings

        # rule_findings: the texts of the findings that the rules already reported.
        def initialize(skill:, work_package:, user:, rule_findings: [])
          @skill = skill
          @work_package = work_package
          @user = user
          @rule_findings = rule_findings
        end

        def lock_version
          @lock_version ||= work_package.reload.lock_version
        end

        delegate :schema, to: :answer_format

        def user_message
          AI::Assistance::WorkPackageContext.new(work_package:, user:).to_h.merge(
            rule_findings:,
            change_options: change_options.for_prompt
          ).to_json
        end

        # Attributes for a finding, or nil when the answer does not qualify. A run stores
        # findings only.
        def finding_attributes(raw)
          answer_format.proposal_attributes(raw)&.then { |attributes| attributes if attributes[:severity] }
        end

        def answer_format
          @answer_format ||= AI::Assistance::AnswerFormat.new(AI::Assistance::ProposalBuilder.new(change_options))
        end

        private

        def change_options
          @change_options ||= AI::Assistance::ChangeOptions.new(keys: skill.changeable_attributes, work_package:, user:)
        end
      end
    end
  end
end
