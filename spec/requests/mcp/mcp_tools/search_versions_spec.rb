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

RSpec.describe McpTools::SearchVersions do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "X-Authentication-Scheme", "Bearer"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:admin) } # using an admin, so that versions are visible
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_versions",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let(:project) { create(:project) }

  let!(:version_not_shared) { create(:version, project:, sharing: :none, name: "v1.0.1-alpha") }
  let!(:version_shared_globally) { create(:version, project:, sharing: :system, name: "v1.1.0") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all versions without filters" do
      subject
      expect(parsed_results.dig("structuredContent", "items").size).to eq(2)
    end

    it "responds with properly formatted versions" do
      subject
      parsed_results.dig("structuredContent", "items").each do |version|
        expect(version.to_json).to match_json_schema.from_docs("version_read_model")
      end
    end

    context "when passing an exact name" do
      let(:call_args) { { name: "v1.0.1-alpha" } }

      it "finds the version" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
      end
    end

    context "when passing a non-exact name" do
      let(:call_args) { { name: "alpha" } }

      it "finds the version" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
      end
    end

    context "when passing a version sharing strategy" do
      let(:call_args) { { sharing: "system" } }

      it "finds the version" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
      end

      context "and when passing a version name" do
        let(:call_args) { { sharing: "system", name: "v1" } }

        it "finds the version" do
          subject
          expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        end
      end

      context "and when passing a version name of a version with a different sharing strategy" do
        let(:call_args) { { sharing: "system", name: "alpha" } }

        it "does not find the version" do
          subject
          expect(parsed_results.dig("structuredContent", "items")).to be_empty
        end
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_versions) { 5 }
      let(:version_count) { page_size + overspilling_versions }
      let(:call_args) { { name: "beta" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        version_count.times do |idx|
          create(:version, sharing: :none, name: "v1.2.#{idx}-beta")
        end
      end

      it "returns only results up to the page size" do
        subject
        expect(parsed_results.dig("structuredContent", "items").count).to eq(page_size)
      end

      context "if another page is requested" do
        let(:call_args) { { name: "beta", page: 2 } }

        it "returns the requested page" do
          subject
          expect(parsed_results.dig("structuredContent", "items").count).to eq(overspilling_versions)
        end
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
