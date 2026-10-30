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

RSpec.describe "Configuring a project's own variant in the creation wizard", :js do
  include Workflows::EditHelpers

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status, name: "New") }
  shared_let(:status_b) { create(:status, name: "In progress") }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:bookshop_form) { create(:form_configuration, name: "Bookshop form") }
  shared_let(:bookshop_flow) { create(:named_workflow, name: "Bookshop flow") }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  let(:variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }

  current_user { project_admin }

  before do
    variant.update!(workflow: create(:named_workflow, name: "Internal flow"))
    create(:status_transition, workflow: variant.workflow, role:, old_status: status_a, new_status: status_b)
    create(:status_transition, workflow: bookshop_flow, role:, old_status: status_a, new_status: status_b)
  end

  def visit_step(step, **)
    visit project_type_variant_creation_wizard_path(project_id: project, type_id: type.id, variant_id: variant.id,
                                                    step:, **)
  end

  describe "the form step" do
    it "offers only the picker, without the choice to configure a new form", :aggregate_failures do
      visit_step(:form_configuration)

      expect(page).to have_test_selector("form_configuration-selector", text: variant.form_configuration.name)
      expect(page).to have_no_test_selector("form_configuration-choice-existing")
      expect(page).to have_no_test_selector("form_configuration-choice-new")
    end

    it "does not show the banner about editing the form" do
      visit_step(:form_configuration)

      expect(page).to have_test_selector("form_configuration-selector")
      expect(page).to have_no_test_selector("form-configuration-read-only")
    end

    it "switches to another form and stays on the step" do
      visit_step(:form_configuration)

      find_test_selector("form_configuration-selector").click
      within_test_selector("form_configuration-panel") { click_link "Bookshop form" }

      expect(page).to have_current_path(/step=form_configuration/)
      expect(page).to have_test_selector("form_configuration-selector", text: "Bookshop form")
      expect(variant.reload.form_configuration).to eq(bookshop_form)
    end
  end

  describe "the workflows step" do
    it "offers only the picker, without the choice to configure a new workflow", :aggregate_failures do
      visit_step(:workflows, role_ids: [role.id])

      expect(page).to have_test_selector("workflow-selector", text: variant.workflow.name)
      expect(page).to have_no_test_selector("workflow-choice-existing")
      expect(page).to have_no_test_selector("workflow-choice-new")
    end

    it "shows the matrix read-only" do
      visit_step(:workflows, role_ids: [role.id])

      within("#workflow-table") do
        expect(page).to have_field(type: :checkbox, disabled: true, minimum: 1)
        expect(page).to have_no_field(type: :checkbox, disabled: false)
        expect(page).to have_no_link(I18n.t("admin.workflows.status_button"))
        expect(page).to have_no_link(I18n.t(:label_copy_workflow_from_role))
      end
    end

    it "switches to another workflow and finishes the wizard", :aggregate_failures do
      visit_step(:workflows, role_ids: [role.id])

      switch_workflow_to "Bookshop flow"

      expect(page).to have_current_path(/step=workflows/)
      expect(page).to have_test_selector("workflow-selector", text: "Bookshop flow")

      click_on I18n.t(:button_continue)

      expect(page).to have_current_path(/step=pdf/)
      expect(variant.reload.workflow).to eq(bookshop_flow)
    end
  end
end
