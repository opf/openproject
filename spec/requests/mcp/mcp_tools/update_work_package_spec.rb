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

RSpec.describe McpTools::UpdateWorkPackage do
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
        name: "update_work_package",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      id: work_package.id,
      data: {
        lockVersion: work_package.lock_version,
        subject: "The new subject"
      }
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:work_package) { create(:work_package, identifier: "PROJ-1337").reload }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
    work_package.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "updates the work package" do
      expect { mcp_request }.not_to change(WorkPackage, :count)

      expect(work_package.reload.subject).to eq("The new subject")
    end

    it "responds with a properly formatted work package" do
      mcp_request

      expect(result_item.to_json).to match_json_schema.from_docs("work_package_model")
    end

    context "when using a wrong lock version" do
      let(:call_args) do
        {
          id: work_package.id,
          data: {
            subject: "My new subject",
            lockVersion: work_package.lock_version + 42
          }
        }
      end

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("Information has been updated by at least one other user in the meantime.")
      end

      it "does not update the work package" do
        expect { mcp_request }.not_to change { work_package.reload.subject }
      end
    end

    context "when finding the work package via its semantic identifier" do
      let(:call_args) do
        {
          id: work_package.identifier,
          data: {
            lockVersion: work_package.lock_version,
            subject: "The new subject"
          }
        }
      end

      it "updates the work package" do
        expect { mcp_request }.not_to change(WorkPackage, :count)

        expect(work_package.reload.subject).to eq("The new subject")
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
