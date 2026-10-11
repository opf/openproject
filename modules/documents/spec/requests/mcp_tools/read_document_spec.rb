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

RSpec.describe McpTools::ReadDocument,
               with_settings: {
                 collaborative_editing_hocuspocus_url: "wss://hocuspocus.local",
                 collaborative_editing_hocuspocus_secret: "secret12345",
                 real_time_text_collaboration_enabled: true
               } do
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

  let(:project) { create(:project, name: "Docs project") }
  let(:document) { create(:document, :collaborative, project:, title: "Meeting notes") }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_documents] }) }
  let(:call_args) { { id: document.id } }
  let(:blocks) { [{ "id" => "a", "type" => "paragraph", "content" => [], "children" => [] }] }
  let(:collaboration_server) do
    instance_double(Documents::CollaborationServer::Client,
                    content: ServiceResult.success(result: { "revision" => "abc", "blocks" => blocks }))
  end

  before do
    server_config.save!
    tool_config.save!

    allow(Documents::CollaborationServer::Client).to receive(:new).and_return(collaboration_server)
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "returns the blocks and revision of the document" do
      mcp_request

      expect(result_item).to eq(
        "id" => document.id,
        "title" => "Meeting notes",
        "project" => { "id" => project.id, "name" => "Docs project" },
        "revision" => "abc",
        "blocks" => blocks
      )
      expect(Documents::CollaborationServer::Client).to have_received(:new).with(user:, document:)
    end

    context "when the collaboration server fails" do
      let(:collaboration_server) do
        instance_double(Documents::CollaborationServer::Client,
                        content: ServiceResult.failure(message: "The collaboration server could not be reached."))
      end

      it "responds with the error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("The collaboration server could not be reached.")
      end
    end

    context "when the document is not visible to the user" do
      let(:user) { create(:user) }

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("The given document could not be found.")
      end
    end

    context "when the document is not collaborative" do
      let(:document) { create(:document, project:, kind: "classic") }

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("Only the content of collaborative documents can be accessed as blocks.")
      end
    end

    context "when real-time collaboration is disabled", with_settings: { real_time_text_collaboration_enabled: false } do
      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("Real-time collaboration on documents is not enabled.")
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds with a 404" do
      mcp_request
      expect(last_response).to have_http_status(404)
    end
  end
end
