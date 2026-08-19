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

RSpec.describe McpTools::SearchUsers do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) do
    # avoid owner for application, so that we don't have additional users created
    create(:oauth_access_token, scopes: "mcp", resource_owner: user, application: create(:oauth_application, owner: nil))
  end
  let(:user) { create(:user) }
  let(:global_permissions) { %i[view_all_principals view_user_email] }

  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_users",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:other_user_karl) { create(:user, firstname: "Karl", lastname: "Kabauter", mail: "kaka@example.com") }
  let!(:other_user_klara) { create(:user, firstname: "Klara", lastname: "König", mail: "klko@example.com") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    create(:global_member, user:, roles: [create(:global_role, permissions: global_permissions)])

    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all users without filters" do
      subject
      expect(parsed_results.dig("structuredContent", "items").size).to eq(3)
    end

    it "responds with properly formatted users" do
      subject
      parsed_results.dig("structuredContent", "items").each do |u|
        expect(u.to_json).to match_json_schema.from_docs("user_model")
      end
    end

    context "when filtering by first name and last name" do
      let(:call_args) { { search_term: "Karl Kabauter" } }

      it "finds the user" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(other_user_karl.id)
      end
    end

    context "when filtering by last name and first name" do
      let(:call_args) { { search_term: "Kabauter Karl" } }

      it "finds the user" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(other_user_karl.id)
      end
    end

    context "when filtering by email address" do
      let(:call_args) { { search_term: "klko@example.com" } }

      it "finds the user" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(other_user_klara.id)
      end

      context "when user lacks view_user_email global permission" do
        let(:global_permissions) { %i[view_all_principals] }

        it "finds the no one" do
          subject
          expect(parsed_results.dig("structuredContent", "items").size).to eq(0)
        end
      end
    end

    context "when filtering on a partial, wrongly-cased term" do
      let(:call_args) { { search_term: "kaba" } }

      it "finds the user" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(other_user_karl.id)
      end
    end

    context "when not allowed to see users" do
      let(:global_permissions) { %i[] }

      it "only finds itself" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
        expect(parsed_results.dig("structuredContent", "items").first.fetch("id")).to eq(user.id)
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_users) { 5 }
      let(:user_count) { page_size + overspilling_users }
      let(:call_args) { { search_term: "Konrad" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        create_list(:user, user_count, firstname: "Konrad")
      end

      it "returns only results up to the page size" do
        subject
        expect(parsed_results.dig("structuredContent", "items").size).to eq(page_size)
      end

      context "if another page is requested" do
        let(:call_args) { { search_term: "Konrad", page: 2 } }

        it "returns the requested page" do
          subject
          expect(parsed_results.dig("structuredContent", "items").size).to eq(overspilling_users)
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
