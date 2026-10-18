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

RSpec.describe AI::Assistance::McpTool do
  shared_let(:project) { create(:project) }
  shared_let(:hidden_project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:visible_wp) { create(:work_package, project:, subject: "Visible") }
  shared_let(:hidden_wp) { create(:work_package, project: hidden_project, subject: "Hidden") }

  let(:record) { create(:ai_assistant_chat_message) }
  let(:llm_call) { AI::Assistance::LlmCall.new(record:, log_tag: "spec") }
  let(:tool) { described_class.for(mcp_class, user:, calls: llm_call.tool_calls) }
  let(:mcp_class) { McpTools::SearchWorkPackages }

  def call(args)
    User.execute_as(user) { JSON.parse(tool.call(args)) }
  end

  describe ".read_only_classes" do
    subject(:names) { described_class.read_only_classes.map(&:name) }

    it "offers the read-only tools only" do
      expect(names).to include("search_work_packages", "list_work_package_comments", "list_statuses")
      expect(names).not_to include("create_work_package", "update_work_package", "create_work_package_comment",
                                   "create_work_package_relation", "delete_work_package_relation")
    end

    it "leaves out the time entries" do
      expect(names).not_to include("search_time_entries")
    end
  end

  it "takes the name, the description and the parameters of the MCP tool" do
    expect(tool.name).to eq("search_work_packages")
    expect(tool.description).to eq(mcp_class.default_description)
    expect(tool.params_schema).to include("type" => "object")
    expect(tool.params_schema["properties"]).to include("project_id", "open")
  end

  it "finds only the work packages that the user can see" do
    expect(call({}).fetch("items").pluck("subject")).to eq(["Visible"])
  end

  it "accepts an id written as in the context" do
    expect(call({ "id" => "##{visible_wp.id}" }).fetch("total")).to eq(1)
  end

  it "drops null for an argument that does not allow it" do
    expect(call({ "project_id" => nil }).fetch("total")).to eq(1)
  end

  it "keeps null for an argument that allows it" do
    expect(call({ "assigned_to_id" => nil }).fetch("total")).to eq(1)
  end

  context "with the structured_only response format", with_config: { mcp_tool_response_format: :structured_only } do
    it "returns the structured content as text" do
      expect(call({}).fetch("total")).to eq(1)
    end
  end

  context "with a resource tool" do
    let(:mcp_class) { McpTools::ListStatuses }

    it "returns the resource text" do
      expect(User.execute_as(user) { tool.call({}) }).to include(Status.first.name)
    end
  end

  context "with a failing call" do
    let(:mcp_class) { McpTools::SearchWorkPackages }

    it "returns an error text and records the error" do
      expect(call({ "group_by" => "author" })).to have_key("error")
      expect(record.events.last).to include("kind" => "tool_call")
      expect(record.events.last["data"]).to include("name" => "search_work_packages", "error" => "KeyError")
    end
  end
end
