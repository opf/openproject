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

require "spec_helper"

RSpec.describe "MCP resources/templates/list" do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp") }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "resources/templates/list",
      params: {}
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:resource_config) { create(:mcp_configuration, identifier: McpResources::StatusList.qualified_name) }
  let(:resource_template_config) { create(:mcp_configuration, identifier: McpResources::Status.qualified_name) }

  before do
    server_config.save!
    resource_config.save!
    resource_template_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP result response"

    it "includes the status resource template" do
      subject

      resource = parsed_results.fetch("resourceTemplates").find { |t| t.fetch("name") == "status" }
      expect(resource).not_to be_nil
      expect(resource.fetch("title")).to eq(resource_config.title)
      expect(resource.fetch("description")).to eq(resource_config.description)
    end

    it "returns a fully qualified uriTemplate" do
      subject

      resource = parsed_results.fetch("resourceTemplates").find { |t| t.fetch("name") == "status" }
      expect(resource.fetch("uriTemplate")).to eq("http://test.host/api/v3/statuses/{id}")
    end

    it "does not include resources" do
      subject

      resource = parsed_results.fetch("resourceTemplates").find { |t| t.fetch("name") == "status_list" }
      expect(resource).to be_nil
    end

    context "when not passing a Bearer token" do
      subject do
        header "Content-Type", "application/json"
        post "/mcp", request_body.to_json
      end

      it_behaves_like "MCP unauthenticated response"
    end

    context "when passing a Bearer token with a wrong scope" do
      let(:access_token) { create(:oauth_access_token, scopes: "api_v3") }

      it_behaves_like "MCP unauthenticated response"
    end

    context "when the MCP server is disabled via configuration" do
      let(:server_config) { create(:mcp_configuration, identifier: "mcp_server", enabled: false) }

      it "responds in a 404" do
        subject
        expect(last_response).to have_http_status(404)
      end
    end

    context "when the status resource template is disabled" do
      let(:resource_template_config) do
        create(:mcp_configuration, identifier: McpResources::Status.qualified_name, enabled: false)
      end

      it_behaves_like "MCP result response"

      it "does not include the status resource template" do
        subject

        resource = parsed_results.fetch("resourceTemplates").find { |t| t.fetch("name") == "status" }
        expect(resource).to be_nil
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds in a 404" do
      subject
      expect(last_response).to have_http_status(404)
    end
  end
end
