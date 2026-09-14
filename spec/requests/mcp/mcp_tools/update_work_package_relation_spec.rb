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

RSpec.describe McpTools::UpdateWorkPackageRelation do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:admin) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "update_work_package_relation",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      id: relation.id,
      description: "The new description."
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:relation) { create(:relates_relation) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!

    relation.save! # making sure creation already happens before expect blocks
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "updates the work package relation in-place" do
      expect { mcp_request }.not_to change(Relation, :count)

      expect(Relation.first).to have_attributes(description: "The new description.")
    end

    it "responds with a properly formatted relation" do
      mcp_request
      expect(parsed_results.fetch("structuredContent").to_json).to match_json_schema.from_docs("relation_read_model")
    end

    context "when setting a valid type" do
      let(:call_args) do
        {
          id: relation.id,
          type: "blocks"
        }
      end

      it "updates the work package relation in-place" do
        expect { mcp_request }.not_to change(Relation, :count)

        expect(Relation.first).to have_attributes(relation_type: "blocks")
      end
    end

    context "when setting an invalid type" do
      let(:call_args) do
        {
          id: relation.id,
          type: "likes"
        }
      end

      it_behaves_like "MCP tool execution error response"
    end

    context "when updating a non-existing relation" do
      let(:call_args) do
        {
          id: relation.id + 100,
          description: "The new description."
        }
      end

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("The given relation could not be found.")
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
