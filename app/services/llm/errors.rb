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
  # The error taxonomy shared by every path that talks to an LLM server.
  #
  # Callers map these onto per-attribute contract errors or health check codes,
  # so the set is deliberately small and describes *what the administrator has to
  # fix*, not what the transport did.
  #
  # Response bodies never appear in a message. An OpenAI-compatible gateway
  # routinely echoes the submitted Authorization header, upstream provider URLs
  # and internal hostnames in its error payloads, and RubyLLM puts exactly that
  # payload into its exception messages (+RubyLLM::Error#initialize+ falls back
  # to +response.body+, and the middleware's own defaults come from parsing the
  # body). #translate therefore discards the incoming message and logs it instead.
  module Errors
    class Error < StandardError; end

    # The server could not be reached at all.
    class ConnectionError < Error; end
    # The host resolved to an address blocked by the SSRF policy.
    class SsrfError < ConnectionError; end
    # The server took too long to answer.
    class TimeoutError < ConnectionError; end
    # The server answered, but rejected our credentials.
    class AuthenticationError < Error; end

    # The server answered with an unexpected status.
    class ApiError < Error
      attr_reader :status

      def initialize(message, status: nil)
        super(message)
        @status = status
      end
    end

    # The prompt exceeded the model's context window.
    class ContextLengthError < ApiError; end
    # The server is throttling us.
    class RateLimitedError < ApiError; end

    # The server answered successfully with something we cannot read.
    class ParseError < Error; end

    # The connection cannot be expressed at all -- an api_format we cannot supply
    # credentials for, or a model the provider refuses to accept.
    class ConfigurationError < Error; end

    # A feature asked for a client before its model resolved. Carries the
    # Llm::Runtime::Resolution status so a caller can tell "no server configured"
    # apart from "this model cannot do that".
    class NotReady < Error
      attr_reader :status

      def initialize(status)
        super("LLM is not ready to serve this feature (#{status})")
        @status = status
      end
    end

    module_function

    # Maps anything RubyLLM or Faraday raised onto this taxonomy.
    #
    # @param error [StandardError]
    # @return [Llm::Errors::Error]
    def translate(error)
      log(error)

      case error
      when Llm::Errors::Error
        error
      when RubyLLM::Error, RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError
        from_ruby_llm(error)
      else
        from_transport(error)
      end
    end

    def from_ruby_llm(error)
      status = status_of(error)

      case error
      when RubyLLM::UnauthorizedError, RubyLLM::ForbiddenError
        AuthenticationError.new("Server rejected the API key (#{status})")
      when RubyLLM::ContextLengthExceededError
        ContextLengthError.new("Prompt exceeds the model's context window", status:)
      when RubyLLM::RateLimitError
        RateLimitedError.new("Server is rate limiting requests", status:)
      when RubyLLM::ConfigurationError, RubyLLM::ModelNotFoundError
        ConfigurationError.new("The connection is not usable as configured")
      else
        # Covers BadRequestError, PaymentRequiredError, ServerError,
        # ServiceUnavailableError, OverloadedError and the middleware's catch-all
        # -- the last of which is how 404/405/501 arrive, i.e. a server that does
        # not implement the endpoint we asked for.
        ApiError.new("Server responded with #{status || 'an error'}", status:)
      end
    end

    def from_transport(error)
      case error
      when Faraday::TimeoutError, Timeout::Error, Errno::ETIMEDOUT
        TimeoutError.new("Request timed out")
      when Faraday::ConnectionFailed, Faraday::SSLError, SocketError, Errno::ECONNREFUSED
        ConnectionError.new(error.class.name)
      when JSON::ParserError
        ParseError.new("Response is not valid JSON")
      else
        Error.new(error.class.name)
      end
    end

    # Runs the block, re-raising any RubyLLM or Faraday failure as an Llm::Errors.
    def wrap
      yield
    rescue StandardError => e
      raise translate(e)
    end

    def status_of(error)
      error.respond_to?(:response) ? error.response&.status : nil
    end

    # The upstream message can embed whatever the server put into the response,
    # up to and including an echoed credential or an internal URL, so only safe
    # metadata is logged.
    def log(error)
      Rails.logger.info { "LLM request failed: #{error.class} (status: #{status_of(error) || 'none'})" }
    end
  end
end
