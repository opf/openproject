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

module Documents
  module CollaborationServer
    class Client
      SCHEMA_PATH = "/api/v1/documents/schema"
      CONTENT_PATH = "/api/v1/documents/content"

      class << self
        def base_url
          configured = Setting.collaborative_editing_hocuspocus_api_url.presence ||
            Setting.collaborative_editing_hocuspocus_url.presence&.sub(/\Aws/i, "http")

          configured&.chomp("/")
        end
      end

      attr_reader :user, :document

      def initialize(user:, document: nil)
        @user = user
        @document = document
      end

      def schema
        request(:get, SCHEMA_PATH, authenticated: false)
      end

      def content
        request(:get, CONTENT_PATH)
      end

      def update_content(revision:, blocks:)
        request(:put, CONTENT_PATH, json: { revision:, blocks: })
      end

      private

      def request(verb, path, authenticated: true, **)
        base_url = self.class.base_url
        return ServiceResult.failure(message: "No collaboration server is configured.") if base_url.blank?

        headers = { "Accept" => "application/json" }
        if authenticated
          token = document_token
          return token if token.failure?

          headers["Authorization"] = "Bearer #{token.result[:encrypted_token]}"
        end

        response = http(base_url, headers).request(verb.to_s.upcase, "#{base_url}#{path}", **)
        handle_response(response)
      end

      def http(base_url, headers)
        server_addresses = OpenProject::SsrfProtection.resolver.call(URI(base_url).host)

        OpenProject.httpx.with(
          headers:,
          safe_private_ranges: OpenProject::Configuration.ssrf_protection_ip_allowlist + server_addresses
        )
      end

      def document_token
        Documents::OAuth::TokenWithMetadataService
          .new(user:, document:, project: document.project)
          .call
      end

      def handle_response(response)
        if response.is_a?(HTTPX::ErrorResponse)
          Rails.logger.error("Failed to reach the collaboration server: #{response.error.message}")
          return ServiceResult.failure(message: "The collaboration server could not be reached.")
        end

        body = parse(response)
        if response.status.in?(200..299)
          ServiceResult.success(result: body)
        else
          ServiceResult.failure(message: error_message(response.status, body), result: body)
        end
      end

      def parse(response)
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        {}
      end

      def error_message(status, body)
        message = body["error"].presence || "The collaboration server responded with status #{status}."
        details = Array(body["errors"]) + Array(body["blockIds"]).map { |id| "Conflicting block: #{id}" }

        [message, *details].join("\n")
      end
    end
  end
end
