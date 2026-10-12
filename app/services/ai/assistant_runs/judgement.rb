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
    #
    # Logs one line when it asks and one when it ends (tag "AI Assistance"). The full
    # prompt, message and answer are logged at debug level only: they hold user content.
    class Judgement
      MAX_FINDINGS = 15
      MAX_ERROR_LENGTH = 255

      attr_reader :run

      def initialize(run)
        @run = run
      end

      def call
        judgement = skill_type.judgement_class.new(run)
        raw_findings = Array(ask(judgement)[:findings])
        kept = store(judgement, raw_findings)
        run.log_event(:stored, findings: raw_findings.size, stored: kept, dropped: @dropped)
        run.update!(status: "finished")
        log(:info, "stored #{kept} of #{raw_findings.size} findings (#{raw_findings.size - kept} dropped)")
      rescue StandardError => e
        fail_judgement(e)
      end

      private

      def skill_type
        AI::AssistantSkills::Registry.fetch(run.skill.skill_key)
      end

      def ask(judgement)
        model_id = ModelChoice.new(run.skill.assistant).model_id
        raise Llm::Errors::NotReady, "no model" unless model_id

        system = system_prompt(judgement)
        message = judgement.user_message
        log(:info, "asking model=#{model_id} system=#{system.size}c message=#{message.size}c")
        run.log_event(:request, model: model_id, system:, message:)
        log(:debug, "system prompt:\n#{system}")
        log(:debug, "message:\n#{message}")

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        answer = Llm::Session.for(LlmConnection.active_connection)
                             .chat(model_id)
                             .with_instructions(system)
                             .with_schema(judgement.schema)
                             .ask(message)
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1)
        content = answer.respond_to?(:content) ? answer.content : answer
        log(:info, "answered in #{duration}s")
        log(:debug, "answer:\n#{content.inspect}")
        run.log_event(:answer, seconds: duration, content: content.is_a?(String) ? content : JSON.pretty_generate(content))

        Llm::StructuredOutput.parse!(answer)
      end

      def system_prompt(_judgement)
        run.skill.system_prompt(locale: run.locale)
      end

      def store(judgement, raw_findings)
        @dropped = []
        AI::AssistantRun.transaction do
          raw_findings.first(MAX_FINDINGS).count do |raw|
            attributes = judgement.finding_attributes(raw)
            unless attributes
              log(:debug, "dropped finding: #{raw.inspect}")
              @dropped << raw.to_h
              next false
            end

            run.findings.create!(attributes.merge(source: "ai", base_lock_version: judgement.lock_version))
          end
        end
      end

      def fail_judgement(error)
        level = error.is_a?(Llm::Errors::Error) ? :warn : :error
        log(level, "failed: #{error.class}: #{error.message}")
        log(:debug, Array(error.backtrace).first(15).join("\n")) if level == :error

        run.reload
        run.log_event(:failure, error: error.class.name, message: error.message.to_s.truncate(2_000))
        run.add_not_checked(:ai_judgement, :failed)
        run.update!(status: "finished",
                    error_message: "#{error.class.name.demodulize}: #{error.message}".truncate(MAX_ERROR_LENGTH))
      rescue StandardError => e
        log(:error, "could not finish the run after a failure: #{e.class}: #{e.message}")
      end

      def log(level, text)
        Rails.logger.tagged("AI Assistance", "run #{run.id}") { Rails.logger.public_send(level, text) }
      end
    end
  end
end
