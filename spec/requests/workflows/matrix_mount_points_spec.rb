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

# Pins the split between the shared matrix editor and the page hosting it: the editor's
# frame carries the inputs and no form of its own, and the host supplies the form that
# submits them. Also exercises the frame body end-to-end, so every route helper the
# editor builds has to resolve.
RSpec.describe "Workflow matrix on the type tab", type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:type) { create(:type) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }
  shared_let(:workflow) do
    create(:workflow, type:, role:, old_status: status_a, new_status: status_b)
  end

  before { login_as admin }

  describe "default role selection" do
    shared_let(:other_role) { create(:project_role) }
    shared_let(:other_transition) do
      create(:status_transition, workflow: type.default_variant.workflow, role: other_role,
                                 old_status: status_a, new_status: status_b, author: true)
    end

    it "selects all used roles in the standalone page, type tab, and creation wizard" do
      [edit_workflow_path(type.default_variant.workflow),
       edit_type_workflow_path(type),
       type_creation_wizard_path(type, step: :workflows)].each do |path|
        get path

        expect(response).to have_http_status(:ok)
        frame = response.parsed_body.at_css("turbo-frame#workflow-table")
        query = Rack::Utils.parse_nested_query(URI.parse(frame["src"]).query)
        expect(query["role_ids"]).to contain_exactly(role.id.to_s, other_role.id.to_s)
      end
    end

    it "groups used roles first and keeps unused roles available" do
      unused_role = create(:project_role, name: "Unused role")
      get type_workflow_matrix_path(type), headers: { "Turbo-Frame" => "workflow-table" }

      panel = response.parsed_body.at_css("[data-test-selector='role-panel']")
      items = panel.css("[data-item-id]")
      expect(items.first(2).pluck("data-item-id")).to contain_exactly(role.id.to_s, other_role.id.to_s)
      expect(panel.css(".ActionList-sectionDivider").map(&:text)).to eq(["With transitions", "Without transitions"])
      expect(items.pluck("data-item-id")).to include(unused_role.id.to_s)
    end
  end

  it "renders the matrix frame with the transition menu and no form of its own" do
    get type_workflow_matrix_path(type, tab: "always", role_ids: [role.id]),
        headers: { "Turbo-Frame" => "workflow-table" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Default transitions")
    expect(response.body).to include("status[#{status_a.id}][#{status_b.id}]")
    expect(response.body).to include(Workflows::MatrixEditorComponent::STATE_ID)
    expect(response.body).to have_field("tab", type: :hidden, with: "always")
    expect(response.body).to have_field("role_ids[]", type: :hidden, with: role.id.to_s)
    expect(response.body).not_to include("<form")
  end

  it "carries the tab and roles in the frame when the tab has no transitions" do
    get workflow_matrix_path(type.default_variant.workflow, tab: "author", role_ids: [role.id]),
        headers: { "Turbo-Frame" => "workflow-table" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("admin.workflows.blankslate.title"))
    expect(response.body).to have_field("tab", type: :hidden, with: "author")
    expect(response.body).to have_field("role_ids[]", type: :hidden, with: role.id.to_s)
  end

  it "renders the standalone workflow page with the form and Save around the lazy frame" do
    workflow = type.default_variant.workflow

    get edit_workflow_path(workflow, tab: "author")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("turbo-frame")
    expect(response.body).to include("action=\"#{workflow_matrix_path(workflow)}\"")
    expect(response.body).to have_css(".workflow-save-bar button[type=submit]", text: I18n.t(:button_save))
  end

  it "renders the type edit page shell around the lazy frame, with nothing to submit" do
    get edit_type_workflow_path(type)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("turbo-frame")
    expect(response.body).to have_no_css(".workflow-save-bar")
  end

  it "says where the transitions are edited instead" do
    get type_workflow_matrix_path(type, tab: "always", role_ids: [role.id]),
        headers: { "Turbo-Frame" => "workflow-table" }

    workflow_page = edit_workflow_path(type.default_variant.workflow)

    expect(response.body).to have_css("[data-test-selector='workflow-read-only']")
    expect(response.body).to have_css("[data-test-selector='workflow-read-only'] a[href='#{workflow_page}']")
  end

  it "offers the workflow picker and the create action" do
    get type_workflow_matrix_path(type, tab: "always", role_ids: [role.id]),
        headers: { "Turbo-Frame" => "workflow-table" }

    expect(response.body).to have_css("[data-test-selector='workflow-selector']",
                                      text: type.default_variant.workflow.name)
    expect(response.body).to have_css("[data-test-selector='workflow-create-new']")
  end

  describe "a variant of its own" do
    shared_let(:variant) { create(:type_variant, type:, variant_name: "Mobile") }

    def get_matrix
      get type_variant_workflow_matrix_path(type_id: type.id, variant_id: variant.id,
                                            tab: "always", role_ids: [role.id]),
          headers: { "Turbo-Frame" => "workflow-table" }
    end

    it "says the workflow is the one its type uses" do
      variant.update!(workflow: type.default_variant.workflow)

      get_matrix

      expect(response.body).to have_css("[data-test-selector='workflow-selector']",
                                        text: I18n.t("workflows.selector.same_as_type"))
    end

    it "says nothing of the sort once it has a workflow of its own" do
      variant.update!(workflow: create(:named_workflow, name: "Mobile flow"))

      get_matrix

      expect(response.body).to have_css("[data-test-selector='workflow-selector']", text: "Mobile flow")
      expect(response.body).to have_no_css("[data-test-selector='workflow-selector']",
                                           text: I18n.t("workflows.selector.same_as_type"))
    end
  end

  it "rests on reusing a workflow until the step says which one it started" do
    get type_creation_wizard_path(type, step: :workflows)

    expect(response.body).to have_css("[data-test-selector='workflow-choice-existing'][checked]")
    expect(response.body).to have_css("[data-test-selector='workflow-panel']")

    get type_creation_wizard_path(type, step: :workflows,
                                        started_workflow_id: type.default_variant.workflow_id)

    expect(response.body).to have_css("[data-test-selector='workflow-choice-new'][checked]")
    expect(response.body).to have_no_css("[data-test-selector='workflow-panel']")
  end

  it "leaves the picker and the create action out of the wizard's matrix" do
    get type_workflow_matrix_path(type, tab: "always", role_ids: [role.id], wizard: true),
        headers: { "Turbo-Frame" => "workflow-table" }

    expect(response.body).to have_no_css("[data-test-selector='workflow-selector']")
    expect(response.body).to have_no_css("[data-test-selector='workflow-create-new']")
  end

  it "names the workflow in force in the wizard once another variant shares it" do
    create(:type, name: "Shared with").default_variant.update!(workflow: type.default_variant.workflow)

    get type_creation_wizard_path(type, step: :workflows)

    expect(response.body).to have_css("[data-test-selector='workflow-choice-existing'][checked]")
    expect(response.body).to have_css("[data-test-selector='workflow-selector']",
                                      text: type.default_variant.workflow.name)
  end
end
