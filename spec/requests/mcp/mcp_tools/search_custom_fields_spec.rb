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

RSpec.describe McpTools::SearchCustomFields do
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

  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_custom_fields",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:custom_field_one) { create(:wp_custom_field, name: "One custom field") }
  let!(:custom_field_two) { create(:wp_custom_field, name: "Another field") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all custom fields without filters" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").size).to eq(2)
    end

    it "responds with properly formatted custom fields" do
      mcp_request
      parsed_results.dig("structuredContent", "items").each do |cf|
        expect(cf.to_json).to match_json_schema.from_docs("custom_field_model")
      end
    end

    context "when filtering by the full custom field name" do
      let(:call_args) { { name: "One custom field" } }

      it "finds the custom field" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(custom_field_one.id)
      end
    end

    context "when filtering on a partial, wrongly-cased term" do
      let(:call_args) { { name: "cUstom" } }

      it "finds the custom field" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(custom_field_one.id)
      end
    end

    context "when not allowed to see the custom field" do
      let(:user) { create(:user) }

      it "does not find the custom field" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(0)
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_fields) { 5 }
      let(:field_count) { page_size + overspilling_fields }
      let(:call_args) { { name: "user custom" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        create_list(:user_custom_field, field_count)
      end

      it "returns only results up to the page size" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(page_size)
      end

      context "if another page is requested" do
        let(:call_args) { { name: "user custom", page: 2 } }

        it "returns the requested page" do
          mcp_request
          expect(parsed_results.dig("structuredContent", "items").size).to eq(overspilling_fields)
        end
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
