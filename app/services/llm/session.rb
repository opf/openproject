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
  # Turns an LlmConnection into something that can issue requests.
  #
  # Every inference request in OpenProject goes through here, so that the
  # administrator's stored settings -- endpoint, credential, custom headers --
  # are applied in exactly one place.
  #
  # Note that RubyLLM builds its own Faraday connection over net_http and so
  # does *not* pass through OpenProject.httpx and its SSRF filter. Inference
  # traffic to an administrator-supplied base URL is therefore not SSRF
  # filtered. This is a deliberate, recorded decision. Model discovery
  # deliberately stays on Llm::Client, which is filtered.
  class Session
    # RubyLLM exposes a single Faraday timeout rather than Llm::Client's
    # connect/read/request triple, so those three values collapse to one.
    # RubyLLM's own default is 300s, which is far too long to hold a Rails
    # worker for a check.
    PROBE_TIMEOUT = 20
    INFERENCE_TIMEOUT = 180

    # Formats whose credentials an LlmConnection cannot express: Bedrock needs a
    # secret key and a region as well as a key, Vertex AI a project and a
    # location. The model has a single api_key column.
    UNSUPPORTED_FORMATS = %w[bedrock vertexai].freeze

    # A self-hosted OpenAI-compatible server frequently needs no credential at
    # all, but RubyLLM's ensure_configured! raises when a provider declares
    # <slug>_api_key as required and none is set. A placeholder gets us past
    # that check; a server that wants no credential ignores it.
    PLACEHOLDER_API_KEY = "-"

    class << self
      def for(connection, timeout: INFERENCE_TIMEOUT, max_retries: 1)
        new(connection, timeout:, max_retries:)
      end

      def supports?(api_format)
        UNSUPPORTED_FORMATS.exclude?(api_format.to_s)
      end
    end

    def initialize(connection, timeout: INFERENCE_TIMEOUT, max_retries: 1)
      @connection = connection
      @timeout = timeout
      @max_retries = max_retries

      unless self.class.supports?(connection.api_format)
        raise Llm::Errors::ConfigurationError,
              "#{connection.api_format} needs credentials an LLM connection cannot store"
      end
    end

    def provider
      @provider ||= connection.api_format.to_sym
    end

    # Translates failures raised by a chat's own request methods.
    #
    # RubyLLM::Chat is a builder: the request happens later, when the caller
    # invokes #ask, long after this class has returned. Extending the instance
    # is what makes the error taxonomy hold for that call too, rather than
    # relying on every caller to remember to wrap it. The with_* builder methods
    # return self, so the extension survives them.
    module TranslatesErrors
      def complete(...)
        Llm::Errors.wrap { super }
      end
    end

    # @param model_id [String]
    # @return [RubyLLM::Chat]
    def chat(model_id)
      Llm::Errors.wrap do
        context.chat(model: model_id, provider:, assume_model_exists: true)
               .extend(TranslatesErrors)
      end
    end

    # @param input [String, Array<String>]
    # @return [RubyLLM::Embedding]
    def embed(input, model:, dimensions: nil)
      Llm::Errors.wrap do
        context.embed(input, model:, provider:, assume_model_exists: true, dimensions:)
      end
    end

    private

    attr_reader :connection, :timeout, :max_retries

    # A per-call context rather than RubyLLM.configure: the global configuration
    # is process-wide, and writing an administrator's endpoint and credential
    # into it would leak them across requests and across tenants.
    def context
      @context ||= RubyLLM.context do |config|
        config.public_send(:"#{provider}_api_base=", connection.base_url)
        apply_credentials(config)

        config.openproject_custom_headers = connection.custom_headers
        config.request_timeout = timeout
        # RubyLLM retries POSTs three times by default, so one completion can be
        # billed four times. Callers state what they are willing to pay for.
        config.max_retries = max_retries
        config.logger = Rails.logger
      end
    end

    def apply_credentials(config)
      key = connection.api_key.presence || (PLACEHOLDER_API_KEY if api_key_required?)

      config.public_send(:"#{provider}_api_key=", key) if key
    end

    # Asked of the gem rather than hard-coded: which providers insist on a key,
    # as opposed to accepting a bare base URL, is RubyLLM's business and changes
    # between releases.
    def api_key_required?
      RubyLLM::Provider.resolve(provider)
                       .configuration_requirements
                       .include?(:"#{provider}_api_key")
    end
  end
end
