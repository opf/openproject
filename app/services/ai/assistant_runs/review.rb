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
  module AssistantRuns
    # Asks the model for findings the rules cannot see, and stores the ones that cite
    # evidence. Any failure keeps the rule findings, lists the AI part as not checked and
    # finishes the run, so the dialog never waits for a run that will not finish.
    class Review
      MAX_FINDINGS = 15
      # Low, so that one work package gives the same findings from run to run.
      TEMPERATURE = 0.2

      attr_reader :run

      def initialize(run)
        @run = run
      end

      def call
        review = run.skill.skill_type.review_class.new(skill: run.skill, work_package: run.work_package, user: run.user,
                                                       rule_findings: run.findings.rule.map(&:text))
        raw_findings = Array(ask(review)[:proposals])
        kept = store(review, raw_findings)
        run.log_event(:stored, findings: raw_findings.size, stored: kept, dropped: @dropped)
        run.update!(status: "finished")
        log(:info, "stored #{kept} of #{raw_findings.size} findings (#{raw_findings.size - kept} dropped)")
      rescue StandardError => e
        fail_review(e)
      end

      private

      def ask(review)
        model_id = run.skill.assistant.effective_model_id
        raise Llm::Errors::NotReady, "no model" unless model_id

        llm_call.ask(model_id:, system: run.skill.system_prompt(locale: run.locale),
                     message: review.user_message, schema: review.schema, temperature: TEMPERATURE)
      end

      def store(review, raw_findings)
        @dropped = []
        AI::AssistantRun.transaction do
          raw_findings.first(MAX_FINDINGS).count do |raw|
            attributes = review.finding_attributes(raw)
            unless attributes
              log(:debug, "dropped finding: #{raw.inspect}")
              @dropped << raw.to_h
              next false
            end

            run.findings.create!(attributes.merge(source: "ai", base_lock_version: review.lock_version))
          end
        end
      end

      def fail_review(error)
        run.reload
        llm_call.record_failure(error)
        run.add_not_checked(:ai_review, :failed)
        run.update!(status: "finished")
      rescue StandardError => e
        log(:error, "could not finish the run after a failure: #{e.class}: #{e.message}")
      end

      def llm_call
        @llm_call ||= AI::Assistance::LlmCall.new(record: run, log_tag: "run #{run.id}")
      end

      def log(level, text) = llm_call.log(level, text)
    end
  end
end
