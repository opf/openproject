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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe McpTools::SearchLabels do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_roles: { project => role }) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_labels",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_items) { parsed_results.dig("structuredContent", "items") }

  let!(:urgent) { create(:label, name: "Urgent") }
  let!(:frontend) { create(:label, name: "Frontend") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all labels ordered by name without filters" do
      mcp_request
      expect(result_items.pluck("id")).to eq([frontend.id, urgent.id])
    end

    it "responds with properly formatted labels" do
      mcp_request
      result_items.each do |label|
        expect(label.to_json).to match_json_schema.from_docs("label_model")
      end
    end

    context "when passing a partial name" do
      let(:call_args) { { name: "ront" } }

      it "finds the matching label" do
        mcp_request
        expect(result_items.pluck("id")).to contain_exactly(frontend.id)
      end
    end

    context "when the user cannot view work packages anywhere" do
      let(:user) { create(:user) }

      it "does not find any labels" do
        mcp_request
        expect(result_items).to be_empty
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_labels) { 5 }
      let(:label_count) { page_size + overspilling_labels }
      let(:call_args) { { name: "Paginated" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        label_count.times { |idx| create(:label, name: "Paginated #{idx}") }
      end

      it "returns only results up to the page size" do
        mcp_request
        expect(result_items.count).to eq(page_size)
      end

      it "indicates the total number of results" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "total")).to eq(label_count)
      end

      context "if another page is requested" do
        let(:call_args) { { name: "Paginated", page: 2 } }

        it "returns the requested page" do
          mcp_request
          expect(result_items.count).to eq(overspilling_labels)
        end
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
