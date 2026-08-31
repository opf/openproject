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

RSpec.describe McpTools::CreateWorkPackage do
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
        name: "create_work_package",
        arguments: call_args
      }
    }
  end
  let(:call_args) do
    {
      data: {
        subject: "My subject",
        _links: {
          status: { href: "/api/v3/statuses/#{status.id}" },
          type: { href: "/api/v3/types/#{type.id}" },
          project: { href: "/api/v3/projects/#{project.id}" }
        }
      }
    }
  end
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }

  let(:project) { create(:project).tap { |p| p.project_types.create!(type:) } }
  let(:type) { create(:type) }
  let(:status) { create(:status) }
  let!(:priority) { create(:default_priority) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "creates a new work package" do
      expect { mcp_request }.to change(WorkPackage, :count).from(0).to(1)

      wp = WorkPackage.first
      expect(wp.subject).to eq("My subject")
      expect(wp.status).to eq(status)
      expect(wp.type).to eq(type)
      expect(wp.project).to eq(project)
    end

    it "responds with a properly formatted work package" do
      mcp_request

      expect(result_item.to_json).to match_json_schema.from_docs("work_package_model")
    end

    context "when setting an unexpected type" do
      let(:wrong_type) { create(:type) }

      let(:call_args) do
        {
          data: {
            subject: "My subject",
            _links: {
              status: { href: "/api/v3/statuses/#{status.id}" },
              type: { href: "/api/v3/types/#{wrong_type.id}" },
              project: { href: "/api/v3/projects/#{project.id}" }
            }
          }
        }
      end

      it "responds with an error" do
        mcp_request
        expect(result_item.fetch("error")).to eq("Type is not set to one of the allowed values.")
      end

      it "does not create a work package" do
        expect { mcp_request }.not_to change(WorkPackage, :count)
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
