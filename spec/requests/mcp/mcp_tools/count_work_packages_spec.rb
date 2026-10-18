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

RSpec.describe McpTools::CountWorkPackages do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: { name: "count_work_packages", arguments: call_args }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result) { parsed_results.fetch("structuredContent") }

  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:open_status) { create(:status, name: "Open one") }
  let(:closed_status) { create(:closed_status, name: "Closed one") }
  let(:assignee) { create(:user, firstname: "Ada", lastname: "Assignee", member_with_permissions: { project => [] }) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    create(:work_package, project:, status: open_status, assigned_to: assignee)
    create(:work_package, project:, status: open_status)
    create(:work_package, project:, status: closed_status)
    create(:work_package, project: other_project, status: open_status)
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "counts only the work packages that the user can see" do
      mcp_request
      expect(result).to eq("total" => 3)
    end

    context "with a project filter" do
      let(:call_args) { { project_id: other_project.id } }

      it "counts nothing in a project that the user cannot see" do
        mcp_request
        expect(result).to eq("total" => 0)
      end
    end

    context "with open: true" do
      let(:call_args) { { open: true } }

      it "counts only open work packages" do
        mcp_request
        expect(result).to eq("total" => 2)
      end
    end

    context "when grouped by status" do
      let(:call_args) { { group_by: "status" } }

      it "returns the count per status, the largest first" do
        mcp_request
        expect(result["total"]).to eq(3)
        expect(result["groups"]).to eq([{ "name" => "Open one", "count" => 2 }, { "name" => "Closed one", "count" => 1 }])
      end
    end

    context "when grouped by assignee" do
      let(:call_args) { { group_by: "assignee", open: true } }

      it "names the assignees, and counts unassigned work packages as (none)" do
        mcp_request
        expect(result["groups"]).to contain_exactly({ "id" => assignee.id, "name" => "Ada Assignee", "count" => 1 },
                                                    { "name" => "(none)", "count" => 1 })
      end
    end

    context "when grouped by assignee for a list of people" do
      let(:idle) { create(:user, firstname: "Ida", lastname: "Idle", member_with_permissions: { project => [] }) }
      let(:call_args) { { group_by: "assignee", open: true, assigned_to_id: [assignee.id, idle.id] } }

      it "lists every one of them, also with no work packages" do
        mcp_request
        expect(result["groups"]).to eq([{ "id" => assignee.id, "name" => "Ada Assignee", "count" => 1 },
                                        { "id" => idle.id, "name" => "Ida Idle", "count" => 0 }])
      end
    end

    context "with an unknown group" do
      let(:call_args) { { group_by: "author" } }

      it "rejects the call" do
        mcp_request
        expect(parsed_results["isError"]).to be(true)
      end
    end
  end
end
