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

require "spec_helper"

RSpec.describe McpTools::SearchDocuments do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: described_class.name,
        arguments: call_args
      }
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  let(:result_items) { result_item.fetch("items") }
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_documents], other_project => %i[view_documents] })
  end
  let(:call_args) { {} }

  let!(:collaborative_document) { create(:document, :collaborative, project:, title: "Meeting notes") }
  let!(:classic_document) { create(:document, project: other_project, kind: "classic", title: "Handbook") }
  let!(:invisible_document) { create(:document, title: "Secret notes") }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all visible documents" do
      mcp_request
      expect(result_items.pluck("id")).to contain_exactly(collaborative_document.id, classic_document.id)
    end

    it "returns a condensed representation" do
      mcp_request

      item = result_items.find { |i| i["id"] == collaborative_document.id }
      expect(item.keys).to contain_exactly("_links", "id", "title", "collaborative", "createdAt", "updatedAt")
      expect(item["_links"].keys).to contain_exactly("self", "project")
      expect(item["collaborative"]).to be(true)
    end

    describe "filtering by title" do
      let(:call_args) { { title: "notes" } }

      it "finds documents with a matching title" do
        mcp_request
        expect(result_items.pluck("id")).to eq([collaborative_document.id])
      end
    end

    describe "filtering by project" do
      let(:call_args) { { project_id: other_project.id } }

      it "finds documents of the project" do
        mcp_request
        expect(result_items.pluck("id")).to eq([classic_document.id])
      end
    end
  end
end
