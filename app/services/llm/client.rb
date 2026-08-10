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
  # A thin client for an OpenAI-API-compatible server.
  #
  # The configured base URL is expected to already contain the API version segment
  # (for example +https://example.com/v1+), matching what every provider documents
  # and what every OpenAI client library expects. This client only appends the
  # endpoint path.
  #
  # Errors are raised as a small taxonomy so that callers can map them onto
  # per-attribute contract errors rather than leaking transport detail into the UI.
  # Response bodies are never included in error messages: an OpenAI-compatible
  # gateway routinely echoes the submitted Authorization header, upstream provider
  # URLs and internal hostnames in its error payloads.
  class Client
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

    # The server answered successfully with something that is not an OpenAI model list.
    class ParseError < Error; end

    # The global httpx defaults (connect 3s / read 3s / request 10s, all
    # writable: false) are tuned for storage and webhook calls and are far too
    # tight for an inference endpoint. Every call site must override them.
    PROBE_TIMEOUT = {
      timeout: { connect_timeout: 5, read_timeout: 15, request_timeout: 20 }
    }.freeze

    INFERENCE_TIMEOUT = {
      timeout: { connect_timeout: 5, read_timeout: 120, request_timeout: 180 }
    }.freeze

    def initialize(base_url:, api_key: nil, timeout: PROBE_TIMEOUT, headers: {})
      @base_url = base_url.to_s.chomp("/")
      @api_key = api_key
      @timeout = timeout
      @headers = (headers || {}).compact_blank
    end

    # The model catalogue as the server reports it, verbatim.
    #
    # Kept verbatim on purpose: vLLM adds +max_model_len+ and +root+ to each card,
    # which is the only trustworthy source for a deployment's real context window.
    #
    # @return [Hash] the parsed +GET /models+ body
    def models
      body = get("/models")

      raise ParseError, "Response does not contain a model list" unless body.is_a?(Hash) && body["data"].is_a?(Array)

      body
    end

    # Requests an embedding vector for a single short input.
    #
    # Used to determine whether a model can serve embeddings at all: the model
    # list says nothing about it, and posting a chat completion to an embedding
    # model (or the reverse) is the only reliable way to find out.
    #
    # @return [Hash] the parsed +POST /embeddings+ body
    def embeddings(model:, input:)
      post("/embeddings", { model:, input: })
    end

    private

    attr_reader :base_url, :api_key, :timeout, :headers

    def post(path, payload)
      response = session.post(uri_for(path), json: payload)
      handle_transport_error(response) if response.is_a?(HTTPX::ErrorResponse)
      handle_status(response)
      parse(response)
    rescue OpenProject::HttpxSsrfFilter::ServerSideRequestForgeryError
      raise SsrfError, "Host resolves to a blocked address"
    end

    def get(path)
      response = session.get(uri_for(path))
      # A connection-level failure yields an HTTPX::ErrorResponse. A real response
      # carrying a 4xx/5xx is an ordinary HTTPX::Response — note that its #error
      # is also populated (it delegates to #raise_for_status), so the response
      # class, not #error, is what distinguishes the two.
      handle_transport_error(response) if response.is_a?(HTTPX::ErrorResponse)
      handle_status(response)
      parse(response)
    rescue OpenProject::HttpxSsrfFilter::ServerSideRequestForgeryError
      # Raised from HttpxSsrfFilter#addresses=; the throw/catch path surfaces as
      # response.error instead and is handled in #handle_transport_error.
      raise SsrfError, "Host resolves to a blocked address"
    end

    def session
      request = OpenProject.httpx.with(timeout)
      request = request.with(headers:) if headers.any?
      api_key.present? ? request.plugin(:auth).bearer_auth(api_key) : request
    end

    def uri_for(path)
      URI.parse("#{base_url}#{path}")
    rescue URI::InvalidURIError
      raise ConnectionError, "Invalid URL"
    end

    def handle_transport_error(response)
      error = response.error

      case error
      when OpenProject::HttpxSsrfFilter::ServerSideRequestForgeryError
        raise SsrfError, "Host resolves to a blocked address"
      when HTTPX::TimeoutError
        raise TimeoutError, "Request timed out"
      else
        raise ConnectionError, error.class.name
      end
    end

    def handle_status(response)
      status = response.status
      return if status.in?(200..299)

      raise AuthenticationError, "Server rejected the API key (#{status})" if status.in?([401, 403])

      raise ApiError.new("Server responded with #{status}", status:)
    end

    # Parses the body directly rather than through HTTPX's +#json+, which insists on a
    # JSON content type. Self-hosted servers behind a proxy do not reliably set one,
    # and a content-type mismatch is not a reason to call a working server broken.
    def parse(response)
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      raise ParseError, "Response is not valid JSON"
    end
  end
end
