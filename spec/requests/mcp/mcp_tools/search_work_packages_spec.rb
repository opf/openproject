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

RSpec.describe McpTools::SearchWorkPackages do
  subject do
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
        name: "search_work_packages",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_items) { parsed_results.dig("structuredContent", "items") }

  let(:project) { create(:project) }
  let(:type) { create(:type) }
  let(:status) { create(:status) }
  let(:version) { create(:version, project:) }
  let(:assignee) { create(:user) }
  let(:author) { create(:user) }

  let!(:work_package_a) do
    create(:work_package,
           project:,
           type:,
           status:,
           version:,
           assigned_to: assignee,
           author:,
           subject: "First Work Package")
  end

  let!(:work_package_b) do
    create(:work_package,
           project:,
           type:,
           status:,
           subject: "Second Work Package")
  end

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all work packages without filters" do
      subject
      expect(result_items.size).to eq(2)
    end

    it "responds with properly formatted work packages" do
      subject
      result_items.each do |work_package|
        expect(work_package.to_json).to match_json_schema.from_docs("work_package_model")
      end
    end

    describe "filtering by id" do
      let(:call_args) { { id: work_package_a.id } }

      it "finds the work package" do
        subject
        expect(result_items.size).to eq(1)
        expect(result_items.first["id"]).to eq(work_package_a.id)
      end
    end

    describe "filtering by project_id" do
      let!(:other_work_package) { create(:work_package, subject: "Other Project WP") }

      let(:call_args) { { project_id: project.id } }

      it "finds only work packages in the specified project" do
        subject
        expect(result_items.size).to eq(2)
        expect(result_items.pluck("id")).to contain_exactly(work_package_a.id, work_package_b.id)
      end
    end

    describe "filtering by status_id" do
      let!(:other_status_wp) { create(:work_package, project:, subject: "Different Status WP") }

      let(:call_args) { { status_id: status.id } }

      it "finds only work packages with the specified status" do
        subject
        expect(result_items.size).to eq(2)
        expect(result_items.pluck("id")).to contain_exactly(work_package_a.id, work_package_b.id)
      end
    end

    describe "filtering by type_id" do
      let!(:other_type_wp) { create(:work_package, project:, subject: "Different Type WP") }

      let(:call_args) { { type_id: type.id } }

      it "finds only work packages with the specified type" do
        subject
        expect(result_items.size).to eq(2)
        expect(result_items.pluck("id")).to contain_exactly(work_package_a.id, work_package_b.id)
      end
    end

    describe "filtering by assigned_to_id" do
      context "when searching for assigned work packages" do
        let(:call_args) { { assigned_to_id: assignee.id } }

        it "finds only work packages assigned to the specified user" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_a.id)
        end
      end

      context "when searching for unassigned work packages" do
        let(:call_args) { { assigned_to_id: nil } }

        it "finds only unassigned work packages" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_b.id)
        end
      end
    end

    describe "filtering by author_id" do
      let(:call_args) { { author_id: author.id } }

      it "finds only work packages created by the specified user" do
        subject
        expect(result_items.size).to eq(1)
        expect(result_items.first["id"]).to eq(work_package_a.id)
      end
    end

    describe "filtering by version_id" do
      context "when searching for work packages with a specific version" do
        let(:call_args) { { version_id: version.id } }

        it "finds only work packages with the specified version" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_a.id)
        end
      end

      context "when searching for work packages without a version" do
        let(:call_args) { { version_id: nil } }

        it "finds only work packages without a version" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_b.id)
        end
      end
    end

    describe "filtering by subject" do
      context "with exact subject" do
        let(:call_args) { { subject: "First Work Package" } }

        it "finds the work package" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_a.id)
        end
      end

      context "with partial subject" do
        let(:call_args) { { subject: "First" } }

        it "finds the work package" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_a.id)
        end
      end

      context "with case-insensitive search" do
        let(:call_args) { { subject: "first work" } }

        it "finds the work package" do
          subject
          expect(result_items.size).to eq(1)
          expect(result_items.first["id"]).to eq(work_package_a.id)
        end
      end

      context "with common term" do
        let(:call_args) { { subject: "Work Package" } }

        it "finds all matching work packages" do
          subject
          expect(result_items.size).to eq(2)
        end
      end
    end

    describe "combining multiple filters" do
      let(:call_args) { { project_id: project.id, assigned_to_id: assignee.id } }

      it "applies all filters" do
        subject
        expect(result_items.size).to eq(1)
        expect(result_items.first["id"]).to eq(work_package_a.id)
      end
    end

    context "when user cannot see work packages" do
      let(:user) { create(:user) }

      it "does not find any work packages" do
        subject
        expect(result_items).to be_empty
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_work_packages) { 5 }
      let(:work_packages_count) { page_size + overspilling_work_packages }
      let(:call_args) { { subject: "Stormtrooper" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        work_packages_count.times do |idx|
          create(:work_package,
                 project:,
                 type:,
                 status:,
                 subject: "Send Stormtrooper squad No. #{idx} to Jedi temple on Coruscant")
        end
      end

      it "returns only results up to the page size" do
        subject
        expect(parsed_results.dig("structuredContent", "items").count).to eq(page_size)
      end

      context "if another page is requested" do
        let(:call_args) { { subject: "Stormtrooper", page: 2 } }

        it "returns the requested page" do
          subject
          expect(parsed_results.dig("structuredContent", "items").count).to eq(overspilling_work_packages)
        end
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds with a 404" do
      subject
      expect(last_response).to have_http_status(404)
    end
  end
end
