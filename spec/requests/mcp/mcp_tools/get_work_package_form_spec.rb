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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe McpTools::GetWorkPackageForm do
  subject(:mcp_request) do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "get_work_package_form",
        arguments: call_args
      }
    }
  end
  let(:call_args) { { project_id: project.id, type_id: type.id } }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }
  let(:result_item) { parsed_results.fetch("structuredContent") }
  let(:payload) { result_item.dig("_embedded", "payload") }
  let(:schema) { result_item.dig("_embedded", "schema") }

  let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }
  let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:list_custom_field) do
    create(:list_wp_custom_field, name: "Severity", is_required: true, possible_values: %w[low high], default_option: "high")
  end
  let(:user_custom_field) { create(:user_wp_custom_field, name: "Reviewer") }
  let(:type) do
    create(:type,
           default_work_package_description: "## Steps to reproduce",
           custom_fields: [list_custom_field, user_custom_field])
  end
  let(:project) { create(:project).tap { |p| p.project_types.create!(type:) } }

  let!(:default_status) { create(:default_status) }
  let!(:next_status) { create(:status) }
  let!(:unreachable_status) { create(:status) }
  let!(:priority) { create(:default_priority) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    create(:status_transition, type:, role:, old_status: default_status, new_status: next_status)

    server_config.save!
    tool_config.save!
  end

  it_behaves_like "MCP text tool"

  it "returns the description template of the type as default" do
    mcp_request

    expect(payload.fetch("description")).to eq("format" => "markdown", "raw" => "## Steps to reproduce")
  end

  it "returns the default status, priority, project and type as links" do
    mcp_request

    expect(payload.dig("_links", "status", "href")).to eq("/api/v3/statuses/#{default_status.id}")
    expect(payload.dig("_links", "priority", "href")).to eq("/api/v3/priorities/#{priority.id}")
    expect(payload.dig("_links", "project", "href")).to eq("/api/v3/projects/#{project.id}")
    expect(payload.dig("_links", "type", "href")).to eq("/api/v3/types/#{type.id}")
  end

  it "returns the default value of custom fields" do
    mcp_request

    high = list_custom_field.custom_options.find_by(value: "high")
    expect(payload.dig("_links", list_custom_field.attribute_name(:camel_case), "href"))
      .to eq("/api/v3/custom_options/#{high.id}")
  end

  it "lists the allowed statuses according to the workflow" do
    mcp_request

    expect(schema.dig("status", "_links", "allowedValues"))
      .to contain_exactly(
        { "href" => "/api/v3/statuses/#{default_status.id}", "title" => default_status.name },
        { "href" => "/api/v3/statuses/#{next_status.id}", "title" => next_status.name }
      )
  end

  it "describes the custom fields of the type" do
    mcp_request

    expect(schema.fetch(list_custom_field.attribute_name(:camel_case)))
      .to include("name" => "Severity",
                  "type" => "CustomOption",
                  "required" => true,
                  "location" => "_links",
                  "_links" => { "allowedValues" => contain_exactly(include("title" => "low"),
                                                                   include("title" => "high")) })
  end

  it "keeps the link to allowed values that are not listed" do
    mcp_request

    expect(schema.dig("assignee", "_links", "allowedValues")).to include("href")
    expect(schema.dig(user_custom_field.attribute_name(:camel_case), "_links", "allowedValues")).to include("href")
  end

  it "omits read-only fields" do
    mcp_request

    expect(schema.keys).not_to include("id", "createdAt", "updatedAt")
  end

  it "omits embedded allowed values" do
    mcp_request

    expect(schema.values.grep(Hash)).to all(satisfy { |property| !property.key?("_embedded") })
  end

  it "omits action links" do
    mcp_request

    expect(result_item["_links"]).to be_empty
  end

  it "omits html renderings" do
    mcp_request

    expect(payload.fetch("description")).not_to have_key("html")
  end

  it "omits attribute groups, dependencies and validation errors" do
    mcp_request

    expect(schema.keys).not_to include("_attributeGroups", "_dependencies")
    expect(result_item.fetch("_embedded")).not_to have_key("validationErrors")
  end

  it "does not create a work package" do
    expect { mcp_request }.not_to change(WorkPackage, :count)
  end

  context "when the form configuration of the type contains only some fields" do
    let(:type) do
      create(:type,
             custom_fields: [list_custom_field],
             attribute_groups: [["Details", ["priority", "estimated_time", "custom_field_#{list_custom_field.id}"]]])
    end

    it "omits fields that are not placed in the form" do
      mcp_request

      expect(schema.keys).not_to include("labels", "category", "assignee", "responsible", "startDate", "dueDate",
                                         "duration", "scheduleManually", "ignoreNonWorkingDays",
                                         "remainingTime", "percentageDone")
    end

    it "keeps the fields placed in the form" do
      mcp_request

      expect(schema.keys).to include("priority", "estimatedTime", list_custom_field.attribute_name(:camel_case))
    end

    it "keeps the fields that are always part of the form" do
      mcp_request

      expect(schema.keys).to include("subject", "description", "type", "status", "project", "parent")
    end
  end

  context "when the form configuration of the type contains the date" do
    let(:type) { create(:type, attribute_groups: [["Details", ["date"]]]) }

    it "keeps the scheduling fields but not the progress fields" do
      mcp_request

      expect(schema.keys).to include("startDate", "dueDate", "duration", "scheduleManually", "ignoreNonWorkingDays")
      expect(schema.keys).not_to include("estimatedTime", "remainingTime", "percentageDone")
    end
  end

  context "when multiple versions are disabled", with_settings: { work_package_multiple_versions: false } do
    let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_packages assign_versions]) }

    context "and the form configuration of the type does not contain the target versions" do
      let(:type) { create(:type, attribute_groups: [["Details", ["priority"]]]) }

      it "offers no version field" do
        mcp_request

        expect(schema.keys).not_to include("version", "targetVersions")
      end
    end

    context "and the form configuration of the type contains the target versions" do
      let(:type) { create(:type, attribute_groups: [["Details", ["target_versions"]]]) }

      it "offers the target versions but not the deprecated version field" do
        mcp_request

        expect(schema.keys).to include("targetVersions")
        expect(schema.keys).not_to include("version")
      end
    end
  end

  shared_examples "an invalid combination of arguments" do
    it "responds with an error naming the accepted combinations" do
      mcp_request

      expect(result_item.fetch("error"))
        .to eq("Pass project_id and type_id for a new work package, or work_package_id for an existing one. " \
               "Add type_id to work_package_id to describe a type change.")
    end
  end

  context "when not passing any arguments" do
    let(:call_args) { {} }

    it_behaves_like "an invalid combination of arguments"
  end

  context "when passing only the project" do
    let(:call_args) { { project_id: project.id } }

    it_behaves_like "an invalid combination of arguments"
  end

  context "when passing both a work package and a project" do
    let(:work_package) { create(:work_package, project:, type:) }
    let(:call_args) { { work_package_id: work_package.id, project_id: project.id, type_id: type.id } }

    it_behaves_like "an invalid combination of arguments"
  end

  context "when the type is not enabled in the project" do
    let(:call_args) { { project_id: project.id, type_id: create(:type).id } }

    it "responds with an error" do
      mcp_request

      expect(result_item.fetch("error")).to eq("The given type is not enabled in this project.")
    end
  end

  context "when the project is not visible to the user" do
    let(:call_args) { { project_id: create(:project).id, type_id: type.id } }

    it "responds with an error" do
      mcp_request

      expect(result_item.fetch("error")).to eq("The given project could not be found.")
    end
  end

  context "when the user may not add work packages" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }

    it "responds with an error" do
      mcp_request

      expect(result_item.fetch("error")).to eq("You are not allowed to create work packages in this project.")
    end
  end

  context "when passing an existing work package" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
    let(:work_package) do
      create(:work_package, project:, type:, status: next_status, subject: "Existing", description: "Current description")
    end
    let(:call_args) { { work_package_id: work_package.id } }

    it "returns the current values" do
      mcp_request

      expect(payload.fetch("subject")).to eq("Existing")
      expect(payload.fetch("description")).to eq("format" => "markdown", "raw" => "Current description")
      expect(payload.dig("_links", "status", "href")).to eq("/api/v3/statuses/#{next_status.id}")
    end

    it "lists the allowed statuses starting from the current status" do
      mcp_request

      expect(schema.dig("status", "_links", "allowedValues"))
        .to contain_exactly({ "href" => "/api/v3/statuses/#{next_status.id}", "title" => next_status.name })
    end

    it "describes the custom fields of the type" do
      mcp_request

      expect(schema.fetch(list_custom_field.attribute_name(:camel_case))).to include("name" => "Severity")
    end

    it "omits action links" do
      mcp_request

      expect(result_item["_links"]).to be_empty
    end

    it "does not change the work package" do
      expect { mcp_request }.not_to change { work_package.reload.updated_at }
    end

    context "and a type" do
      let(:other_type) { create(:type, custom_fields: [user_custom_field]) }
      let(:call_args) { { work_package_id: work_package.id, type_id: other_type.id } }

      before { project.project_types.create!(type: other_type) }

      it "describes the work package changed to that type" do
        mcp_request

        expect(payload.dig("_links", "type", "href")).to eq("/api/v3/types/#{other_type.id}")
        expect(schema.keys).to include(user_custom_field.attribute_name(:camel_case))
        expect(schema.keys).not_to include(list_custom_field.attribute_name(:camel_case))
      end
    end

    context "and a type that is not enabled in the project" do
      let(:call_args) { { work_package_id: work_package.id, type_id: create(:type).id } }

      it "responds with an error" do
        mcp_request

        expect(result_item.fetch("error")).to eq("The given type is not enabled in this project.")
      end
    end

    context "when the work package is not visible to the user" do
      let(:work_package) { create(:work_package) }

      it "responds with an error" do
        mcp_request

        expect(result_item.fetch("error")).to eq("The given work package could not be found.")
      end
    end

    context "when the user may not edit the work package" do
      let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }

      it "responds with an error" do
        mcp_request

        expect(result_item.fetch("error")).to eq("You are not allowed to edit this work package.")
      end
    end
  end
end
