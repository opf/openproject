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

RSpec.describe McpTools::CreateWorkPackageComment do
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
        name: "create_work_package_comment",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      work_package_id: work_package.id,
      comment: "This is a comment I'd like to add."
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:work_package) { create(:work_package, identifier: "PROJ-101").reload }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
    work_package.save!

    work_package.project.update!(enabled_internal_comments: true)
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server internal_comments] do
    it_behaves_like "MCP text tool"

    it "adds a work package comment" do
      expect { mcp_request }.to change { work_package.reload.journals.count }.by(1)

      expect(work_package.reload.journals.last.notes).to eq("This is a comment I'd like to add.")
    end

    it "responds with a properly formatted activity" do
      mcp_request

      expect(result_item.to_json).to match_json_schema.from_docs("work_package_activities_model")
    end

    context "when specifying the work package via semantic identifier" do
      let(:call_args) do
        {
          work_package_id: work_package.identifier,
          comment: "This is a comment I'd like to add."
        }
      end

      it "adds a work package comment" do
        expect { mcp_request }.to change { work_package.reload.journals.count }.by(1)

        expect(work_package.reload.journals.last.notes).to eq("This is a comment I'd like to add.")
      end
    end

    context "when requesting to create an internal comment" do
      let(:call_args) do
        {
          work_package_id: work_package.id,
          comment: "This is a comment I'd like to add.",
          internal: true
        }
      end

      it "creates an internal comment" do
        expect { mcp_request }.to change { work_package.reload.journals.count }.by(1)

        expect(work_package.reload.journals.last).to be_restricted
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
