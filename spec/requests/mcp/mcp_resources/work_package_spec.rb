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

RSpec.describe McpResources::WorkPackage do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:admin) } # using an admin, to ensure visibility of everything
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "resources/read",
      params: { uri: resource_uri }
    }
  end
  let(:resource_uri) { "http://test.host/api/v3/work_packages/#{work_package.id}" }

  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let(:work_package) { create(:work_package) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:resource_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    resource_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text resource response"

    it "responds with a properly formatted work package" do
      subject
      text_content = parsed_results.fetch("contents").first
      wp = text_content.fetch("text")
      expect(wp).to match_json_schema.from_docs("work_package_model")
    end

    context "when the resource is disabled via configuration" do
      let(:resource_config) { create(:mcp_configuration, identifier: described_class.qualified_name, enabled: false) }

      it_behaves_like "MCP empty resource response"
    end

    context "when requesting a non-existing work package" do
      let(:resource_uri) { "http://test.host/api/v3/work_packages/#{work_package.id + 1}" }

      it_behaves_like "MCP empty resource response"
    end

    context "when requesting a work package not visible to the user" do
      let(:user) { create(:user) }

      it_behaves_like "MCP empty resource response"
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds in a 404" do
      subject
      expect(last_response).to have_http_status(404)
    end
  end
end
