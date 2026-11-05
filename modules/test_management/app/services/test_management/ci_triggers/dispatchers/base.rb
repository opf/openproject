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

module TestManagement
  module CiTriggers
    module Dispatchers
      class Base
        TIMEOUT_SECONDS = 15
        USER_AGENT = "OpenProject-TestManagement"

        Result = Struct.new(:status, :url, :external_id, :error, keyword_init: true) do
          def triggered? = status == "triggered"
        end

        class RequestFailed < StandardError; end

        # shortcut: GitHub only, other providers in PR6
        REGISTRY = { "github" => "TestManagement::CiTriggers::Dispatchers::Github" }.freeze

        def self.for(connection) = REGISTRY.fetch(connection.provider).constantize.new(connection:)

        def initialize(connection:)
          @connection = connection
        end

        def call(ref:, inputs:)
          dispatch(ref:, inputs: inputs.transform_keys(&:to_s).transform_values(&:to_s))
        rescue RequestFailed => e
          failed(e.message)
        rescue StandardError => e
          failed(CiConnections::Http.describe(e, connection))
        end

        protected

        attr_reader :connection

        def dispatch(**) = raise(TestManagement::AbstractMethodError)

        def base_url = connection.effective_base_url
        def repository = connection.repository
        def token = connection.decrypted_token
        def enc(value) = ERB::Util.url_encode(value.to_s)

        def http
          @http ||= CiConnections::Http.session(timeout: TIMEOUT_SECONDS)
        end

        def post(url, headers: {}, json: nil)
          options = { headers: default_headers.merge(headers) }
          options[:json] = json unless json.nil?
          checked(http.post(url, **options))
        end

        def default_headers
          { "User-Agent" => USER_AGENT, "Accept" => "application/json" }
        end

        def checked(response)
          if CiConnections::Http.error_response?(response)
            raise RequestFailed, CiConnections::Http.describe(response.error, connection)
          end

          response
        end

        def code(response) = response.status.to_i

        def json(response)
          parsed = JSON.parse(response.body.to_s)
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end

        def triggered(url: nil, external_id: nil)
          Result.new(status: "triggered", url: safe_url(url), external_id: external_id&.to_s&.first(255))
        end

        def failed(message)
          Result.new(status: "failed", error: scrub(message.to_s).first(500))
        end

        def http_failure(response)
          body = json(response)
          detail = body["message"] || body["error"] || body["errors"]
          detail = detail.join(", ") if detail.is_a?(Array)
          failed(["HTTP #{code(response)}", detail.is_a?(String) ? detail.first(300) : nil].compact.join(": "))
        end

        def scrub(text)
          [token].compact_blank.reduce(text) { |memo, secret| memo.gsub(secret, "[FILTERED]") }
        end

        def safe_url(url)
          url = url.to_s
          url.match?(%r{\Ahttps?://}i) ? url.first(1024) : nil
        end
      end
    end
  end
end
