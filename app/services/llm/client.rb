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
  # A thin model-discovery client for an OpenAI-API-compatible server.
  #
  # Inference goes through Llm::Session and RubyLLM. Discovery deliberately
  # stays here, for two reasons. RubyLLM's model parsing discards max_model_len
  # and root, which are the only trustworthy statement of a self-hosted
  # deployment's real context window, and it substitutes OpenAI's capability
  # heuristics for arbitrary model ids. And this path runs on OpenProject.httpx,
  # so it is covered by the SSRF filter that RubyLLM's own Faraday stack bypasses.
  #
  # The configured base URL is expected to already contain the API version segment
  # (for example +https://example.com/v1+), matching what every provider documents
  # and what every OpenAI client library expects. This client only appends the
  # endpoint path.
  #
  # Errors come from Llm::Errors, which is shared with the RubyLLM-backed
  # inference path. They are aliased here because every existing caller rescues
  # them by their Llm::Client:: name, and both names refer to the same classes.
  class Client
    Error = Llm::Errors::Error
    ConnectionError = Llm::Errors::ConnectionError
    SsrfError = Llm::Errors::SsrfError
    TimeoutError = Llm::Errors::TimeoutError
    AuthenticationError = Llm::Errors::AuthenticationError
    ApiError = Llm::Errors::ApiError
    ParseError = Llm::Errors::ParseError

    # The global httpx defaults (connect 3s / read 3s / request 10s, all
    # writable: false) are tuned for storage and webhook calls and are far too
    # tight for an inference endpoint. Every call site must override them.
    PROBE_TIMEOUT = {
      timeout: { connect_timeout: 5, read_timeout: 15, request_timeout: 20 }
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

    private

    attr_reader :base_url, :api_key, :timeout, :headers

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
