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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Choosing a workflow in the type creation wizard", :js do
  include Workflows::EditHelpers
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status, name: "New") }
  shared_let(:status_b) { create(:status, name: "In progress") }

  shared_let(:other_type) { create(:type, name: "Feature") }
  shared_let(:existing) { other_type.default_variant.workflow }

  before_all do
    existing.update!(name: "Standard flow", description: "The agreed one")
    create(:workflow, workflow: existing, role:, old_status: status_a, new_status: status_b)
  end

  let(:type) { create(:type, name: "Bug") }
  let(:variant) { type.default_variant }
  let(:start_title) { I18n.t("workflows.start.title") }

  current_user { admin }

  def visit_step = visit type_creation_wizard_path(type, step: :workflows, role_ids: [role.id])

  def choose_option(name)
    wait_for_turbo_stream { find_test_selector("workflow-choice-#{name}").click }
  end

  def expect_chosen(name)
    expect(page).to have_css("[data-test-selector='workflow-choice-#{name}']:checked", visible: :all)
  end

  def transitions_of(workflow) = workflow.status_transitions.pluck(:old_status_id, :new_status_id)

  def switch_to_existing(name)
    choose_option("existing")

    within_dialog I18n.t("workflows.change.title") do
      select_autocomplete(find_test_selector("change-workflow-select"),
                          query: name,
                          results_selector: "#change-workflow-dialog")
      click_on I18n.t(:button_save)
    end
  end

  it "offers both starting points and starts a new type on a workflow of its own" do
    visit_step

    expect(page).to have_test_selector("workflow-choice-existing")
    expect_chosen("new")
    expect(variant.workflow).to be_used_by_one_variant
  end

  it "keeps the picker and the create action out of the matrix, which has them on the tab" do
    visit_step

    within("#workflow-table") do
      expect(page).to have_no_test_selector("workflow-selector")
      expect(page).to have_no_test_selector("workflow-create-new")
    end
  end

  it "keeps the matrix editable while the type has a workflow of its own" do
    visit_step

    within("#workflow-table") do
      expect(page).to have_link(I18n.t("admin.workflows.status_button"))
      expect(page).to have_link(I18n.t(:label_copy_workflow_from_role))
    end
  end

  describe "reusing an existing workflow" do
    it "keeps the picker out of the card while a new workflow is configured" do
      visit_step

      expect_chosen("new")
      expect(page).to have_no_test_selector("workflow-selector")
    end

    it "offers the picker once the card is active, and assigns what is picked" do
      visit_step

      switch_to_existing("Standard flow")

      expect(page).to have_current_path(/step=workflows/)
      expect(variant.reload.workflow).to eq(existing)
      expect_chosen("existing")
      expect(page).to have_test_selector("workflow-selector", text: "Standard flow")
    end

    it "offers no way to change the transitions another type is already using" do
      visit_step

      switch_to_existing("Standard flow")

      within("#workflow-table") do
        expect(page).to have_no_link(I18n.t("admin.workflows.status_button"))
        expect(page).to have_no_link(I18n.t(:label_copy_workflow_from_role))
      end
    end

    it "leaves the transitions of the reused workflow alone on the way out" do
      visit_step

      switch_to_existing("Standard flow")
      click_on I18n.t(:button_continue)

      expect(page).to have_current_path(/step=projects/)
      expect(transitions_of(existing)).to contain_exactly([status_a.id, status_b.id])
    end

    it "says nothing about a successful switch, the step speaks for itself" do
      visit_step

      switch_to_existing("Standard flow")

      expect(page).to have_current_path(/step=workflows/)
      expect(page).to have_no_text(I18n.t(:notice_successful_update))
    end
  end

  describe "configuring a new workflow" do
    before { variant.update!(workflow: existing) }

    it "starts from scratch without asking for a name yet" do
      visit_step
      choose_option("new")

      within_dialog start_title do
        choose_workflow_start("scratch")
        click_on I18n.t(:button_continue)
      end

      expect(page).to have_current_path(/step=workflows/)

      started = variant.reload.workflow
      expect(started).not_to eq(existing)
      expect(transitions_of(started)).to be_empty
    end

    it "copies the transitions of the workflow it was told to start from" do
      visit_step
      choose_option("new")

      within_dialog start_title do
        select_autocomplete(find_test_selector("workflow-copy-source"),
                            query: "Standard",
                            results_selector: "#workflow-dialog")
        click_on I18n.t(:button_continue)
      end

      expect(page).to have_current_path(/step=workflows/)

      started = variant.reload.workflow
      expect(started).not_to eq(existing)
      expect(transitions_of(started)).to contain_exactly([status_a.id, status_b.id])
    end

    it "offers the source only while the copy option is selected" do
      visit_step
      choose_option("new")

      within_dialog start_title do
        expect(page).to have_test_selector("workflow-copy-source")

        choose_workflow_start("scratch")
        expect(page).to have_no_test_selector("workflow-copy-source")

        choose_workflow_start("copy")
        expect(page).to have_test_selector("workflow-copy-source")
      end
    end

    it "puts the selection back when the dialog is dismissed" do
      visit_step
      expect_chosen("existing")

      choose_option("new")
      within_dialog(start_title) { click_on I18n.t(:button_cancel) }

      expect_chosen("existing")
      expect(variant.reload.workflow).to eq(existing)
    end
  end
end
