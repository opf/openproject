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
  module TextTransforms
    # Prototype only: talks to an OpenAI-compatible endpoint configured through
    # environment variables. The real implementation resolves the connection
    # through Llm::Runtime once AI-3 is merged (AI-137).
    class PrototypeGateway < Gateway
      ENV_API_KEY = "AI_PROTOTYPE_LLM_API_KEY"
      ENV_BASE_URL = "AI_PROTOTYPE_LLM_BASE_URL"
      ENV_MODEL = "AI_PROTOTYPE_LLM_MODEL"

      def self.configured? = ENV[ENV_API_KEY].present?

      def readiness
        return Readiness.new(false, :not_configured) unless self.class.configured?

        Readiness.new(true, nil)
      end

      def stream(system:, user:, timeout:)
        cancelled = nil
        chat = chat_for(timeout).with_instructions(system)

        response = chat.ask(user) do |chunk|
          content = chunk.content
          next if content.to_s.empty?

          begin
            yield content
          rescue Cancelled => e
            cancelled = e
            raise
          end
        end

        response.content.to_s
      rescue Cancelled
        raise
      rescue StandardError => e
        raise cancelled if cancelled

        raise translate(e)
      end

      private

      def chat_for(timeout)
        llm_context(timeout).chat(model: ENV.fetch(ENV_MODEL, "gpt-4o-mini"),
                                  provider: :openai,
                                  assume_model_exists: true)
      end

      def llm_context(timeout)
        RubyLLM.context do |config|
          config.openai_api_key = ENV.fetch(ENV_API_KEY)
          config.openai_api_base = ENV.fetch(ENV_BASE_URL, "https://api.openai.com/v1")
          config.request_timeout = timeout
          config.max_retries = 0
          config.logger = Rails.logger
        end
      end

      def translate(error)
        Rails.logger.info { "AI prototype gateway failed: #{error.class}" }

        case error
        when Faraday::TimeoutError, ::Timeout::Error, Errno::ETIMEDOUT
          Errors::TimedOut.new(error.class.name)
        when Faraday::ConnectionFailed, Faraday::SSLError, SocketError, Errno::ECONNREFUSED
          Errors::ConnectionFailed.new(error.class.name)
        when RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError
          Errors::NotAvailable.new(error.class.name)
        else
          Errors::Upstream.new(error.class.name)
        end
      end
    end
  end
end
