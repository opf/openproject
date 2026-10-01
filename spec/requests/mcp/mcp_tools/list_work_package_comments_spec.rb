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

RSpec.describe McpTools::ListWorkPackageComments do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) do
    # avoid owner for application, so that we don't have additional users created
    create(:oauth_access_token, scopes: "mcp", resource_owner: user, application: create(:oauth_application, owner: nil))
  end
  let(:user) { create(:user) }

  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "list_work_package_comments",
        arguments: call_args
      }
    }
  end
  let(:call_args) { { work_package_id: work_package.id } }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:work_package) do
    create(:work_package, identifier: "PROJ-42", project: allowed_project, created_at: 5.days.ago, updated_at: 5.days.ago)
  end
  let(:comment) { "I am a comment about the work package." }

  let(:allowed_project) { create(:project, enabled_internal_comments: true) }
  let(:disallowed_project) { create(:project) }

  let(:permissions) { %i[view_work_packages view_internal_comments] }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  let(:activity_creator) do
    # creating three journals and adding a comment to the last one
    (1..3).to_a.reverse_each do |i|
      Timecop.travel(i.hours.ago) do
        WorkPackages::UpdateService.new(model: work_package, user: User.system).call(subject: "Subject ##{i}")
      end
    end

    work_package.journals.last.update!(notes: comment)
  end

  before do
    server_config.save!
    tool_config.save!

    create(:member, project: allowed_project, user:, roles: [create(:project_role, permissions:)])
    create(:member, project: disallowed_project, user:, roles: [create(:project_role, permissions: %i[])])

    activity_creator
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server internal_comments] do
    it_behaves_like "MCP text tool"

    it "finds all comments of the work package" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
    end

    it "hides pure activity updates" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").pluck("comment")).to all(be_present)
    end

    it "hides change details" do
      mcp_request
      expect(parsed_results.dig("structuredContent", "items").pluck("details")).to all(eq([]))
    end

    it "responds with properly formatted activities" do
      mcp_request
      parsed_results.dig("structuredContent", "items").each do |rel|
        expect(rel.to_json).to match_json_schema.from_docs("work_package_activities_model")
      end
    end

    context "when not passing a work_package_id" do
      let(:call_args) { {} }

      it_behaves_like "MCP tool execution error response"
    end

    context "when passing a semantic identifier as work_package_id" do
      let(:call_args) { { work_package_id: work_package.identifier } }

      it "finds all comments of the work package" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
      end
    end

    context "when the comment has emoji reactions" do
      before do
        create(:emoji_reaction, reactable: work_package.journals.last)
      end

      it "embeds the emoji reactions" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items", 0, "_embedded", "emojiReactions", "_embedded", "elements", 0,
                                  "emoji")).to be_present
      end

      it "does not embed other huge resources, such as work packages" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items", 0, "_embedded", "workPackage")).to be_nil
      end
    end

    context "when not allowed to see the source work package" do
      let!(:work_package) { create(:work_package, project: disallowed_project) }

      it "shows an error response" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "error")).to eq("Can't find given work package.")
      end
    end

    context "when there are internal comments" do
      before do
        work_package.journals.last.update!(restricted: true)
      end

      it "shows the internal comments" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").size).to eq(1)
      end

      context "and when the user is not allowed to see internal comments" do
        let(:permissions) { %i[view_work_packages] }

        it "hides the internal comments" do
          mcp_request
          expect(parsed_results.dig("structuredContent", "items").size).to eq(0)
        end
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_comments) { 5 }
      let(:comments_count) { page_size + overspilling_comments }
      let(:call_args) { { work_package_id: work_package.id } }

      let(:activity_creator) do
        (1..comments_count).to_a.reverse_each do |i|
          Timecop.travel(i.hours.ago) do
            WorkPackages::UpdateService.new(model: work_package, user: User.system).call(subject: "Comment update ##{i}")
            work_package.journals.last.update!(notes: "Comment ##{i}")
          end
        end
      end

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)
      end

      it "returns only results up to the page size" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "items").count).to eq(page_size)
      end

      it "indicates the total number of results" do
        mcp_request
        expect(parsed_results.dig("structuredContent", "total")).to eq(comments_count)
      end

      context "if another page is requested" do
        let(:call_args) { { work_package_id: work_package.id, page: 2 } }

        it "returns the requested page" do
          mcp_request
          expect(parsed_results.dig("structuredContent", "items").count).to eq(overspilling_comments)
        end
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds in a 404" do
      mcp_request
      expect(last_response).to have_http_status(404)
    end
  end
end
