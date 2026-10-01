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

RSpec.describe McpTools::ListWorkPackageRelations do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) do
    # avoid owner for application, so that we don't have additional users created
    create(:oauth_access_token, scopes: "mcp", resource_owner: user, application: create(:oauth_application, owner: nil))
  end
  let(:user) { create(:user) }

  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "list_work_package_relations",
        arguments: call_args
      }
    }
  end
  let(:call_args) { { work_package_id: work_package.id } }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:work_package) { create(:work_package, identifier: "PROJ-123", project: allowed_project) }
  let!(:relations) do
    [
      create(:relates_relation, from: work_package),
      create(:follows_relation, successor: work_package, predecessor: create(:work_package, project: work_package.project))
    ]
  end

  let(:allowed_project) { create(:project) }
  let(:disallowed_project) { create(:project) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!

    create(:member, project: allowed_project, user:, roles: [create(:project_role, permissions: %i[view_work_packages])])
    create(:member, project: disallowed_project, user:, roles: [create(:project_role, permissions: %i[])])
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all relations of the work package" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").size).to eq(relations.size)
    end

    it "responds with properly formatted relations" do
      mcp_request
      parsed_results.dig("structuredContent", "items").each do |rel|
        expect(rel.to_json).to match_json_schema.from_docs("relation_read_model")
      end
    end

    context "when not passing a work_package_id" do
      let(:call_args) { {} }

      it_behaves_like "MCP tool execution error response"
    end

    context "when passing a semantic identifier as work_package_id" do
      let(:call_args) { { work_package_id: work_package.identifier } }

      it "finds all relations of the work package" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(relations.size)
      end
    end

    context "when not allowed to see the source work package" do
      let!(:work_package) { create(:work_package, project: disallowed_project) }

      it "shows an error response" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "error")).to eq("Can't find given work package.")
      end
    end

    context "when not allowed to see some related work packages" do
      let!(:relations) do
        [
          create(:relates_relation, from: work_package),
          create(:follows_relation, successor: work_package, predecessor: create(:work_package, project: disallowed_project))
        ]
      end

      it "responds with properly formatted relations" do
        mcp_request
        parsed_results.dig("structuredContent", "items").each do |rel|
          expect(rel.to_json).to match_json_schema.from_docs("relation_read_model")
        end
      end

      it "hides relations to invisible work packages" do
        mcp_request

        results = parsed_results.dig("structuredContent", "items")
        hrefs = results.map { |rel| rel.dig("_links", "to", "href") }

        expect(hrefs).to include("/api/v3/work_packages/#{relations.first.to.id}")
        expect(hrefs).not_to include("/api/v3/work_packages/#{relations.last.to.id}")
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds in a 404" do
      mcp_request
      expect(last_response).to have_http_status(404)
    end
  end
end
