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

RSpec.describe McpTools::SearchTimeEntries do
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
        name: "search_time_entries",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_items) { parsed_results.dig("structuredContent", "items") }

  let(:common_user) { create(:user) }
  let(:time_entries) do
    [
      create(:time_entry, user: common_user),
      create(:time_entry, user: common_user),
      create(:time_entry),
      create(:time_entry),
      yesterdays_time_entry,
      tomorrows_time_entry
    ]
  end
  let(:yesterdays_time_entry) { create(:time_entry, spent_on: Time.zone.yesterday) }
  let(:tomorrows_time_entry) { create(:time_entry, spent_on: Time.zone.tomorrow) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!

    time_entries.each(&:save!)
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all of todays time entries without filters" do
      mcp_request
      expect(result_items.size).to eq(time_entries.size - 2)
    end

    it "responds with properly formatted time entries" do
      mcp_request
      result_items.each do |time_entry|
        expect(time_entry.to_json).to match_json_schema.from_docs("time_entry_model")
      end
    end

    describe "filtering by id" do
      let(:call_args) { { id: time_entries.first.id } }

      it "finds the time entry" do
        mcp_request
        expect(result_items.size).to eq(1)
        expect(result_items.first["id"]).to eq(time_entries.first.id)
      end
    end

    describe "filtering by user_id" do
      let(:call_args) { { user_id: common_user.id } }

      it "finds only time entries with the given user_id" do
        mcp_request
        expect(result_items.size).to eq(2)
        expect(result_items.first["id"]).to eq(time_entries.first.id)
        expect(result_items.second["id"]).to eq(time_entries.second.id)
      end
    end

    describe "filtering by work_package_id" do
      before do
        time_entries.each_with_index do |entry, i|
          entry.entity.assign_attributes(identifier: "PROJ-#{100 + i}", sequence_number: 100 + i)
          entry.entity.save!(context: :identifier_rewrite)
        end
      end

      context "when searching by classic id" do
        let(:call_args) { { work_package_id: time_entries.first.entity_id } }

        it "finds only time entries with the given entity" do
          mcp_request
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(time_entries.first.id)
        end
      end

      context "when searching by semantic id" do
        let(:call_args) { { work_package_id: "PROJ-100" } }

        it "finds only time entries with the given entity" do
          mcp_request
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(time_entries.first.id)
        end
      end
    end

    describe "filtering by spent_since" do
      let(:call_args) { { spent_since: Date.yesterday.iso8601 } }

      it "finds only time entries after or on the given date" do
        mcp_request
        expect(result_items.size).to eq(time_entries.size - 1)
      end
    end

    describe "filtering by spent_until" do
      let(:call_args) { { spent_until: Date.tomorrow.iso8601 } }

      it "finds only time entries before or on the given date" do
        mcp_request
        expect(result_items.size).to eq(time_entries.size - 1)
      end
    end

    describe "combining multiple filters" do
      let(:call_args) { { spent_since: Date.yesterday.iso8601, spent_until: Date.tomorrow.iso8601 } }

      it "applies all filters" do
        mcp_request
        expect(result_items.size).to eq(time_entries.size)
      end
    end

    context "when user cannot see time entries" do
      let(:user) { create(:user) }

      it "does not find any time entries" do
        mcp_request
        expect(result_items).to be_empty
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_time_entries) { 5 }
      let(:time_entries_count) { page_size + overspilling_time_entries }
      let(:time_entries) { create_list(:time_entry, time_entries_count) }
      let(:call_args) { {} }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)
      end

      it "returns only results up to the page size" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").count).to eq(page_size)
      end

      it "indicates the total number of results" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "total")).to eq(time_entries_count)
      end

      context "if another page is requested" do
        let(:call_args) { { page: 2 } }

        it "returns the requested page" do
          mcp_request
          expect(parsed_results.dig("structuredContent", "items").count).to eq(overspilling_time_entries)
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
