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

RSpec.describe "MCP tools/list" do
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
      method: "tools/list",
      params: {}
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: McpTools::SearchProjects.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP result response"

    it "includes the search_projects tool" do
      subject

      tool = parsed_results.fetch("tools").find { |t| t.fetch("name") == "search_projects" }
      expect(tool).not_to be_nil
      expect(tool.fetch("title")).to eq(tool_config.title)
      expect(tool.fetch("description")).to eq(tool_config.description)
    end

    context "when not passing a token" do
      subject do
        header "Content-Type", "application/json"
        post "/mcp", request_body.to_json
      end

      it_behaves_like "MCP unauthenticated response"
    end

    context "when passing an API key via Basic auth" do
      subject do
        header "Authorization", "Basic #{Base64.encode64("apikey:#{apikey.plain_value}")}"
        header "Content-Type", "application/json"
        post "/mcp", request_body.to_json
      end

      let(:apikey) { create(:api_token) }

      it_behaves_like "MCP result response"
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

    context "when the search_projects tool is disabled" do
      let(:tool_config) { create(:mcp_configuration, identifier: McpTools::SearchProjects.qualified_name, enabled: false) }

      it_behaves_like "MCP result response"

      it "does not include the search_projects tool" do
        subject

        tool = parsed_results.fetch("tools").find { |t| t.fetch("name") == "search_projects" }
        expect(tool).to be_nil
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
