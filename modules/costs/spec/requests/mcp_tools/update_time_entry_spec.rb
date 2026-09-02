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

RSpec.describe McpTools::UpdateTimeEntry do
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
        name: "update_time_entry",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      id: time_entry.id,
      data: {
        hours: "PT3H",
        comment: { raw: "The updated comment" }
      }
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:time_entry) { create(:time_entry, hours: 1.0, comments: "The original comment") }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!

    time_entry.save! # making sure creation already happens before expect blocks
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "updates the time entry" do
      expect { mcp_request }.not_to change(TimeEntry, :count)

      time_entry.reload
      expect(time_entry.hours).to eq(3.0)
      expect(time_entry.comments).to eq("The updated comment")
    end

    it "responds with a properly formatted time entry" do
      mcp_request

      expect(result_item.to_json).to match_json_schema.from_docs("time_entry_model")
    end

    context "when passing spentOn" do
      let(:call_args) do
        {
          id: time_entry.id,
          data: {
            spentOn: "2026-07-13"
          }
        }
      end

      it "updates the date of the time entry" do
        mcp_request

        expect(time_entry.reload.spent_on).to eq(Date.iso8601("2026-07-13"))
      end
    end

    context "when the time entry does not exist" do
      let(:call_args) do
        {
          id: 0,
          data: {
            hours: "PT3H"
          }
        }
      end

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("The given time entry could not be found.")
      end
    end

    context "when the user is not allowed to update the time entry" do
      let(:user) do
        create(:user, member_with_permissions: { time_entry.project => %i[view_work_packages view_time_entries] })
      end

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("may not be accessed.")
      end

      it "does not update the time entry" do
        expect { mcp_request }.not_to change { time_entry.reload.comments }
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
