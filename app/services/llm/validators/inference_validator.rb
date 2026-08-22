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

module Llm
  module Validators
    # Whether the server will actually answer a request.
    #
    # This is the only check that proves a connection works, and the only one
    # available at all for a deployment that publishes no model list. It is also
    # the only one that costs money, so it runs on demand rather than on the
    # schedule -- see LlmConnection#deep_health_check.
    #
    # Deliberately absent: probes for tool calling and structured output. Several
    # current vLLM releases answer a tool call with plain text on a fully capable
    # server, deterministically, so a probe would turn a wrong answer into a
    # confident one rather than discovering anything.
    class InferenceValidator < HealthReports::ValidatorGroup
      PROMPT = "ping"

      def self.key = :inference

      private

      def validate
        register_checks(:chat_round_trip)

        model_id = chat_model_id
        return warn_check(:chat_round_trip, :no_model_to_test) if model_id.blank?

        round_trip(model_id)
      end

      def round_trip(model_id)
        answer = session.chat(model_id).with_temperature(0).ask(PROMPT)

        if answer.content.to_s.strip.empty?
          warn_check(:chat_round_trip, :empty_completion, context: { model: model_id })
        else
          pass_check(:chat_round_trip)
        end
      rescue Llm::Errors::AuthenticationError
        fail_check(:chat_round_trip, :invalid_api_key)
      rescue Llm::Errors::TimeoutError
        fail_check(:chat_round_trip, :request_timed_out)
      rescue Llm::Errors::ApiError => e
        fail_check(:chat_round_trip, :chat_failed, context: { model: model_id, status: e.status.to_s })
      rescue Llm::Errors::Error
        fail_check(:chat_round_trip, :connection_error)
      end

      # The configured default first, so the check exercises what features will
      # actually use rather than an arbitrary entry in the catalogue.
      def chat_model_id
        subject.default_chat_model_id.presence || subject.available_model_ids.first
      end

      # Never retried: a failing check should report the failure, not pay for it
      # three more times.
      def session
        Llm::Session.for(subject, timeout: Llm::Session::PROBE_TIMEOUT, max_retries: 0)
      end
    end
  end
end
