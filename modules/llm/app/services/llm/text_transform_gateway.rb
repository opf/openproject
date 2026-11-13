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
  class TextTransformGateway < AI::TextTransforms::Gateway
    FEATURE = :description_assistant

    def readiness
      ready = resolution.ready?
      Readiness.new(ready, ready ? nil : resolution.status)
    end

    def stream(system:, user:, timeout:, &)
      text = complete(system:, user:, timeout:, &).content.to_s
      raise AI::TextTransforms::Errors::Upstream, "empty completion" if text.strip.empty?

      text
    rescue Llm::Errors::Error => e
      raise translate(e)
    end

    private

    class ReasoningRejected < StandardError; end
    private_constant :ReasoningRejected

    def resolution
      @resolution ||= Llm::Runtime.for(FEATURE)
    end

    def complete(system:, user:, timeout:, &)
      ask(chat(system:, timeout:).with_thinking(effort: :none), user, fallback: true, &)
    rescue ReasoningRejected
      ask(chat(system:, timeout:), user, fallback: false, &)
    end

    def chat(system:, timeout:)
      resolution.chat(timeout:, max_retries: 0).with_instructions(system)
    end

    def ask(chat, user, fallback:)
      streamed = false
      consumer_error = nil
      chat.ask(user) do |chunk|
        streamed ||= chunk.content.present?
        yield chunk.content.to_s
      rescue StandardError => e
        consumer_error = e
        raise
      end
    rescue Llm::Errors::Error => e
      raise consumer_error if consumer_error
      raise ReasoningRejected if fallback && !streamed && reasoning_rejected?(e)

      raise
    end

    # Llm::Errors drops the server's message, so the parameter it names is only
    # found on the original RubyLLM error.
    def reasoning_rejected?(error)
      error.instance_of?(Llm::Errors::ApiError) &&
        error.status == 400 &&
        error.cause&.message.to_s.match?(/reasoning|thinking/i)
    end

    def translate(error)
      case error
      when Llm::Errors::NotReady, Llm::Errors::ConfigurationError
        AI::TextTransforms::Errors::NotAvailable.new(error.message)
      when Llm::Errors::RateLimitedError
        AI::TextTransforms::Errors::RateLimited.new(error.message)
      when Llm::Errors::ContextLengthError
        AI::TextTransforms::Errors::ContextTooLong.new(error.message)
      when Llm::Errors::TimeoutError
        AI::TextTransforms::Errors::TimedOut.new(error.message)
      when Llm::Errors::ConnectionError
        AI::TextTransforms::Errors::ConnectionFailed.new(error.message)
      else
        AI::TextTransforms::Errors::Upstream.new(error.message)
      end
    end
  end
end
