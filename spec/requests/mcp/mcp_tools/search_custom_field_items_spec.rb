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

RSpec.describe McpTools::SearchCustomFieldItems do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) do
    # avoid owner for application, so that we don't have additional users created
    create(:oauth_access_token, scopes: "mcp", resource_owner: user, application: create(:oauth_application, owner: nil))
  end
  let(:user) { create(:admin) }
  let(:global_permissions) { %i[view_all_principals view_user_email] }

  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_custom_field_items",
        arguments: call_args
      }
    }
  end
  let(:call_args) { { custom_field_id: custom_field.id } }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:custom_field) do
    create(:wp_custom_field, :hierarchy).tap do |cf|
      service = CustomFields::Hierarchy::HierarchicalItemService.new
      root = cf.hierarchy_root
      hierarchy_items.each do |label|
        service.insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract, parent: root, label:)
      end
    end
  end
  let(:hierarchy_items) { ["the green item", "the red item", "the yellow item"] }

  let!(:other_custom_field) do
    create(:wp_custom_field, :hierarchy).tap do |cf|
      service = CustomFields::Hierarchy::HierarchicalItemService.new
      root = cf.hierarchy_root
      unrelated_items.each do |label|
        service.insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract, parent: root, label:)
      end
    end
  end
  let(:unrelated_items) { %w[unrelated_1 unrelated_2] }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    create(:global_member, user:, roles: [create(:global_role, permissions: global_permissions)])

    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server custom_field_hierarchies] do
    it_behaves_like "MCP text tool"

    it "finds all items of the custom field" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").size).to eq(hierarchy_items.size + 1) # items plus root
    end

    it "finds no items from unrelated custom fields" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").map { |i| i.fetch("label") }).not_to include(*unrelated_items)
    end

    it "responds with properly formatted items" do
      mcp_request
      parsed_results.dig("structuredContent", "items").each do |item|
        expect(item.to_json).to match_json_schema.from_docs("hierarchy_item_read_model")
      end
    end

    it "indicates the total number of results" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "total")).to eq(hierarchy_items.size + 1) # items plus root
    end

    context "when not passing a custom_field_id" do
      let(:call_args) { {} }

      it_behaves_like "MCP tool execution error response"
    end

    context "when filtering by label" do
      let(:call_args) { { custom_field_id: custom_field.id, label: "the green item" } }

      it "finds the item" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("label")).to eq("the green item")
      end
    end

    context "when filtering on a partial, wrongly-cased label" do
      let(:call_args) { { custom_field_id: custom_field.id, label: "Green" } }

      it "finds the item" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("label")).to eq("the green item")
      end
    end

    context "when not allowed to see the custom field" do
      let(:user) { create(:user) }

      it "finds no items" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(0)
      end
    end

    context "when querying a custom field without a hierarchy" do
      let!(:custom_field) { create(:wp_custom_field, :text) }

      it "finds no items" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(0)
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled", with_ee: %i[custom_field_hierarchies] do
    it "responds in a 404" do
      mcp_request
      expect(last_response).to have_http_status(404)
    end
  end
end
