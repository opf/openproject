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

require "httpx/adapters/faraday"

module Llm
  # The stock adapter calls a streaming request's on_data handler without the
  # Faraday env that Faraday 2 passes as its third argument, and with the body
  # still compressed. RubyLLM reads the response status from that env and treats
  # every chunk as an error body when it is missing.
  class SsrfFilteredAdapter < Faraday::Adapter::HTTPX
    module StreamingPlugin
      module RequestMethods
        attr_writer :response_on_data

        def response=(response)
          super

          return unless @response_on_data && @response.is_a?(::HTTPX::Response)

          on_data = @response_on_data
          streamed = @response
          @response.body.on_data = ->(chunk, size) { on_data.call(chunk, size, streamed) }
        end
      end

      module ResponseBodyMethods
        attr_writer :on_data

        def write(chunk)
          return super unless @on_data
          return 0 if chunk.empty?

          decoded = decode_chunk(chunk)
          @on_data.call(decoded, decoded.bytesize)
        end
      end
    end

    self.supports_parallel = false

    def build_connection(env)
      return @connection if @connection

      @connection = ::HTTPX
                      .plugin(ReasonPlugin)
                      .plugin(:ssrf_filter, safe_private_ranges: OpenProject::Configuration.ssrf_protection_ip_allowlist)
                      .plugin(OpenProject::HttpxSsrfCustomErrorMessage)
                      .plugin(StreamingPlugin)
                      .with(options_from_env(env))
    end

    private

    def connect_and_request(env)
      connect(env) do |session|
        request = session.build_request(*build_request(env))
        request.response_on_data = on_data_with_env(env) if env.request.stream_response?

        response = session.request(request)
        response.raise_for_status unless response.is_a?(::HTTPX::Response)
        response
      end
    rescue ::HTTPX::ResolveError, IOError => e
      raise Faraday::ConnectionFailed, e
    end

    def on_data_with_env(env)
      on_data = env.request.on_data
      status_saved = false

      lambda do |chunk, size, response|
        unless status_saved
          save_response(env, response.status, nil, response.headers, response.reason, finished: false)
          status_saved = true
        end

        on_data.call(chunk, size, env)
      end
    end
  end
end
