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

module SquashTMIntegration
  class Client
    API_PATH = "/api/rest/latest"
    BACKEND_PATH = "/backend"

    class Error < StandardError; end
    class ConnectionError < Error; end
    class SsrfError < ConnectionError; end
    class TimeoutError < ConnectionError; end
    class SslError < ConnectionError; end
    class InvalidUrlError < ConnectionError; end

    class UnexpectedStatusError < Error
      attr_reader :status

      def initialize(status)
        @status = status
        super("SquashTM responded with #{status}")
      end
    end

    class AuthenticationError < UnexpectedStatusError; end
    class NotFoundError < UnexpectedStatusError; end
    class ServerError < UnexpectedStatusError; end
    class InvalidResponseError < Error; end

    COLLECTION_PAGE_SIZE = 200

    def self.for(server)
      new(base_url: server.base_url, api_token: server.api_token)
    end

    def initialize(base_url:, api_token:)
      @base_url = base_url.to_s.chomp("/")
      @api_token = api_token
    end

    def projects(page: 0, size: 20)
      get("projects", page:, size:)
    end

    def version
      response = request(uri_for("version", BACKEND_PATH))
      response.fetch("version") { raise InvalidResponseError, "SquashTM version is missing" }
    end

    def all_projects
      collection("projects", "projects")
    end

    def project(id)
      get("projects/#{Integer(id)}")
    end

    def all_requirements(project_id)
      collection("projects/#{Integer(project_id)}/requirements", "requirements", fields: "name,current_version[reference]")
    end

    def requirement(id)
      get("requirements/#{Integer(id)}")
    end

    def test_case(id)
      get("test-cases/#{Integer(id)}")
    end

    def test_case_executions(test_case_id)
      collection("test-cases/#{Integer(test_case_id)}/executions", "executions")
    end

    def project_url(project_id)
      web_url("administration-workspace/projects/#{Integer(project_id)}/content", anchor: "information")
    end

    def test_case_url(test_case_id)
      web_url("test-case-workspace/test-case/#{Integer(test_case_id)}/content", anchor: "information")
    end

    def requirement_url(requirement_id)
      web_url("requirement-workspace/requirement-library/#{Integer(requirement_id)}/content", anchor: "dashboard")
    end

    private

    attr_reader :base_url, :api_token

    def web_url(path, anchor:)
      "#{base_url}/#{path}?#{{ anchor: }.to_query}"
    end

    def collection(path, embedded_key, **query)
      (0..).each_with_object([]) do |page, collected|
        response = get(path, page:, size: COLLECTION_PAGE_SIZE, **query)
        collected.concat(response.dig("_embedded", embedded_key) || [])
        break collected if page + 1 >= response.dig("page", "totalPages").to_i
      end
    end

    def get(path, query = {})
      request(uri_for(path), query)
    end

    def request(uri, query = {})
      response = session.get(uri, params: query)
      handle_transport_error(response) if response.is_a?(HTTPX::ErrorResponse)
      handle_status(response)
      parse(response)
    end

    def session
      OpenProject.httpx.bearer_auth(api_token).with(headers: { "accept" => "application/json" })
    end

    def uri_for(path, path_prefix = API_PATH)
      uri = URI.parse("#{base_url}#{path_prefix}/#{path}")
      raise InvalidUrlError unless uri.is_a?(URI::HTTP) && uri.host.present?

      uri
    rescue URI::InvalidURIError
      raise InvalidUrlError
    end

    def handle_transport_error(response)
      case response.error
      when OpenProject::ServerSideRequestForgeryError then raise SsrfError
      when HTTPX::TimeoutError then raise TimeoutError
      when OpenSSL::SSL::SSLError then raise SslError
      else raise ConnectionError, response.error.class.name
      end
    end

    def handle_status(response)
      return if response.status.in?(200..299)

      raise error_class_for(response.status).new(response.status)
    end

    def error_class_for(status)
      case status
      when 401, 403 then AuthenticationError
      when 404 then NotFoundError
      when 500.. then ServerError
      else UnexpectedStatusError
      end
    end

    def parse(response)
      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      raise InvalidResponseError, "SquashTM response is not valid JSON"
    end
  end
end
