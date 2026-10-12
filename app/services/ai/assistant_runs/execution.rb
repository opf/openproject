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
    # Executes a stored run: the rules in the run's locale, then the AI review in a job
    # when it is available. Callable inline (the menu) or from a job (an automation).
    # Everything acts as the run's user, never as User.current.
    class Execution
      attr_reader :run

      def initialize(run)
        @run = run
      end

      def call
        AI::AssistantRun.transaction do
          run_rules
          run.update!(status: review_status)
        end
        log
        ReviewJob.perform_later(run.id) if run.ai_running?
        run
      end

      private

      def skill_type
        @skill_type ||= AI::AssistantSkills::Registry.fetch(run.skill.skill_key)
      end

      def run_rules
        I18n.with_locale(run.locale) do
          context = skill_type.build_context(work_package: run.work_package, user: run.user)
          skill_type.rules.flat_map { |rule| rule.call(context) }.each do |finding|
            run.findings.create!(finding.to_record_attributes.merge(base_lock_version: run.work_package_lock_version))
          end
          run.not_checked = context.not_checked
        end
      end

      def log
        skipped = run.not_checked.find { |entry| entry["area"] == "ai_review" }&.fetch("reason", nil)
        review = run.ai_running? ? "started" : "skipped (#{skipped || 'none'})"
        run.log_event(:rules, findings: run.findings.size, review:)

        text = "#{run.skill.skill_key} on work package #{run.work_package_id}: " \
               "#{run.findings.size} rule findings, review #{review}"
        Rails.logger.tagged("AI Assistance", "run #{run.id}") { Rails.logger.info(text) }
      end

      def review_status
        if skill_type.review_class.nil?
          "finished"
        elsif run.skill.prompt.blank?
          run.add_not_checked(:ai_review, :no_prompt)
          "finished"
        elsif !LlmConnection.available?
          run.add_not_checked(:ai_review, :no_llm_connection)
          "finished"
        elsif AI::Assistance::ModelChoice.new(run.skill.assistant).model_id.nil?
          run.add_not_checked(:ai_review, :no_model)
          "finished"
        else
          "ai_running"
        end
      end
    end
  end
end
