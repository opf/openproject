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

RSpec.describe "MCP tools/list for documents" do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp") }
  let(:request_body) { { jsonrpc: "2.0", id: "Test-Request", method: "tools/list", params: {} } }
  let(:tool_names) { JSON.parse(last_response.body).dig("result", "tools").pluck("name") }
  let(:document_tools) do
    [McpTools::SearchDocuments, McpTools::GetDocumentSchema, McpTools::ReadDocument, McpTools::UpdateDocumentContent]
  end

  before do
    create(:mcp_configuration, identifier: "mcp_server")
    document_tools.each { |tool| create(:mcp_configuration, identifier: tool.qualified_name) }
  end

  context "with real-time collaboration enabled",
          with_ee: %i[mcp_server],
          with_settings: { real_time_text_collaboration_enabled: true } do
    it "includes all document tools" do
      subject
      expect(tool_names).to include("search_documents", "get_document_schema", "read_document", "update_document_content")
    end
  end

  context "with real-time collaboration disabled",
          with_ee: %i[mcp_server],
          with_settings: { real_time_text_collaboration_enabled: false } do
    it "only includes the document search" do
      subject

      expect(tool_names).to include("search_documents")
      expect(tool_names).not_to include("get_document_schema", "read_document", "update_document_content")
    end
  end
end
