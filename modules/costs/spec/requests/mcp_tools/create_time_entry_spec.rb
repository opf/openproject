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

RSpec.describe McpTools::CreateTimeEntry do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:admin, member_with_permissions: { work_package.project => %i[view_work_package log_time log_own_time] }) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "create_time_entry",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      data: {
        hours: "PT2H30M",
        _links: {
          entity: { href: "/api/v3/work_packages/#{work_package.id}" }
        }
      }
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:work_package) { create(:work_package) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "creates a new time entry" do
      expect { mcp_request }.to change(TimeEntry, :count).from(0).to(1)

      entry = TimeEntry.first
      expect(entry.entity).to eq(work_package)
      expect(entry.user).to eq(user)
      expect(entry.spent_on).to eq(Time.zone.today)
      expect(entry.hours).to eq(2.5)
    end

    it "responds with a properly formatted time entry" do
      mcp_request

      expect(result_item.to_json).to match_json_schema.from_docs("time_entry_model")
    end

    context "when passing a user" do
      let(:assigned_user) { create(:user, member_with_permissions: { work_package.project => %i[view_work_package] }) }
      let(:call_args) do
        {
          data: {
            hours: "PT2H30M",
            _links: {
              entity: { href: "/api/v3/work_packages/#{work_package.id}" },
              user: { href: "/api/v3/users/#{assigned_user.id}" }
            }
          }
        }
      end

      it "creates a time entry for the given user" do
        expect { mcp_request }.to change(TimeEntry, :count).from(0).to(1)

        entry = TimeEntry.first
        expect(entry.user).to eq(assigned_user)
      end
    end

    context "when passing spentOn" do
      let(:call_args) do
        {
          data: {
            hours: "PT2H30M",
            spentOn: "2026-07-13",
            _links: {
              entity: { href: "/api/v3/work_packages/#{work_package.id}" }
            }
          }
        }
      end

      it "creates a time entry for the given date" do
        expect { mcp_request }.to change(TimeEntry, :count).from(0).to(1)

        entry = TimeEntry.first
        expect(entry.spent_on).to eq(Date.iso8601("2026-07-13"))
      end
    end

    context "when passing a comment" do
      let(:call_args) do
        {
          data: {
            hours: "PT2H30M",
            comment: { raw: "My fancy comment" },
            _links: {
              entity: { href: "/api/v3/work_packages/#{work_package.id}" }
            }
          }
        }
      end

      it "creates a time entry with the given comment" do
        expect { mcp_request }.to change(TimeEntry, :count).from(0).to(1)

        entry = TimeEntry.first
        expect(entry.comments).to eq("My fancy comment")
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
