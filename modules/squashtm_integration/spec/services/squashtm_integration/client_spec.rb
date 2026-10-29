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

require "spec_helper"

RSpec.describe SquashTMIntegration::Client, :webmock do
  subject(:client) { described_class.new(base_url: "https://squashtm.example.com/squash/", api_token: "the-token") }

  let(:projects_url) { "https://squashtm.example.com/squash/api/rest/latest/projects?page=0&size=20" }

  describe "#projects" do
    it "returns the parsed response and authenticates with the token" do
      stub_request(:get, projects_url).to_return(status: 200, body: { page: { totalElements: 1 } }.to_json)

      expect(client.projects).to eq("page" => { "totalElements" => 1 })
      expect(WebMock).to have_requested(:get, projects_url).with(headers: { "Authorization" => "Bearer the-token" })
    end

    it "raises an authentication error when the token is rejected" do
      stub_request(:get, projects_url).to_return(status: 401)

      expect { client.projects }.to raise_error(described_class::AuthenticationError)
    end

    it "raises a response error on an unexpected status" do
      stub_request(:get, projects_url).to_return(status: 404)

      expect { client.projects }.to raise_error(described_class::ResponseError)
    end

    it "raises a plain response error on an unexpected client error status" do
      stub_request(:get, projects_url).to_return(status: 422)

      expect { client.projects }.to raise_error(described_class::ResponseError) { |error|
        expect(error).not_to be_a(described_class::ServerError)
      }
    end

    [500, 502, 503, 504].each do |status|
      it "raises a server error with the status when SquashTM or its proxy fails with #{status}" do
        stub_request(:get, projects_url).to_return(status:, body: "Bad Gateway")

        expect { client.projects }.to raise_error(described_class::ServerError) { |error|
          expect(error.status).to eq(status)
        }
      end
    end

    it "raises a response error when the body is not JSON" do
      stub_request(:get, projects_url).to_return(status: 200, body: "<html>Login</html>")

      expect { client.projects }.to raise_error(described_class::ResponseError)
    end

    it "raises an SSRF error when the host is blocked" do
      stub_request(:get, projects_url).to_raise(OpenProject::ServerSideRequestForgeryError.new("blocked"))

      expect { client.projects }.to raise_error(described_class::SsrfError)
    end

    it "raises a timeout error when the server does not answer in time" do
      stub_request(:get, projects_url).to_timeout

      expect { client.projects }.to raise_error(described_class::TimeoutError)
    end

    it "raises an SSL error when the certificate cannot be verified" do
      stub_request(:get, projects_url).to_raise(OpenSSL::SSL::SSLError)

      expect { client.projects }.to raise_error(described_class::SslError)
    end

    it "raises a connection error when the server cannot be reached" do
      stub_request(:get, projects_url).to_raise(Errno::ECONNREFUSED)

      expect { client.projects }.to raise_error(described_class::ConnectionError)
    end

    it "raises an invalid URL error without sending a request" do
      expect { described_class.new(base_url: "not a url", api_token: "x").projects }
        .to raise_error(described_class::InvalidUrlError)
    end
  end

  describe "ids" do
    it "rejects ids that are not numbers before sending a request" do
      expect { client.project("1/../2") }.to raise_error(ArgumentError)
      expect { client.requirement("abc") }.to raise_error(ArgumentError)
      expect { client.test_case(nil) }.to raise_error(TypeError)
    end
  end

  describe "#all_projects" do
    def projects_page(page, total_pages, projects)
      { _embedded: { projects: }, page: { number: page, totalPages: total_pages } }.to_json
    end

    it "collects the projects of all pages" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/projects?page=0&size=200")
        .to_return(status: 200, body: projects_page(0, 2, [{ id: 1, name: "First" }]))
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/projects?page=1&size=200")
        .to_return(status: 200, body: projects_page(1, 2, [{ id: 2, name: "Second" }]))

      expect(client.all_projects.pluck("id", "name")).to eq([[1, "First"], [2, "Second"]])
    end

    it "returns an empty list when SquashTM has no projects" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/projects?page=0&size=200")
        .to_return(status: 200, body: { page: { number: 0, totalPages: 0 } }.to_json)

      expect(client.all_projects).to eq([])
    end
  end

  describe "#all_requirements" do
    it "collects the requirements of the SquashTM project with their references" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/projects/3/requirements")
        .with(query: { page: 0, size: 200, fields: "name,current_version[reference]" })
        .to_return(status: 200, body: { _embedded: { requirements: [{ id: 11, name: "Sign in" }] },
                                        page: { number: 0, totalPages: 1 } }.to_json)

      expect(client.all_requirements(3).pluck("id")).to eq([11])
    end
  end

  describe "#requirement" do
    it "returns the requirement" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/requirements/11")
        .to_return(status: 200, body: { id: 11, name: "Sign in" }.to_json)

      expect(client.requirement(11)).to include("id" => 11)
    end
  end

  describe "#test_case" do
    it "returns the test case" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/test-cases/21")
        .to_return(status: 200, body: { id: 21, description: "<p>Signs in.</p>" }.to_json)

      expect(client.test_case(21)).to include("description" => "<p>Signs in.</p>")
    end
  end

  describe "#test_case_executions" do
    it "collects the executions of the test case" do
      stub_request(:get, "https://squashtm.example.com/squash/api/rest/latest/test-cases/21/executions?page=0&size=200")
        .to_return(status: 200, body: { _embedded: { executions: [{ id: 5, execution_status: "SUCCESS" }] },
                                        page: { number: 0, totalPages: 1 } }.to_json)

      expect(client.test_case_executions(21).pluck("execution_status")).to eq(["SUCCESS"])
    end
  end

  describe "#project" do
    let(:project_url) { "https://squashtm.example.com/squash/api/rest/latest/projects/42" }

    it "returns the project" do
      stub_request(:get, project_url).to_return(status: 200, body: { id: 42, name: "Sandbox" }.to_json)

      expect(client.project(42)).to include("id" => 42, "name" => "Sandbox")
    end

    it "raises a not found error when the project does not exist" do
      stub_request(:get, project_url).to_return(status: 404, body: { status: 404 }.to_json)

      expect { client.project(42) }.to raise_error(described_class::NotFoundError)
    end
  end
end
