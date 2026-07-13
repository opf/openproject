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

RSpec.describe "Jira import select projects modal", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:jira) { create(:jira) }

  current_user { admin }

  let(:available_projects) do
    [
      { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
      { "id" => "10002", "name" => "Project Beta", "key" => "BETA" },
      { "id" => "10003", "name" => "Gamma Project", "key" => "GAMMA" }
    ]
  end

  let(:jira_import) do
    create(:jira_import, jira:, author: admin).tap do |import|
      import.transition_to!(:instance_meta_fetching)
      import.transition_to!(:instance_meta_done)
      import.transition_to!(:configuring)
      import.update!(available: { "projects" => available_projects })
    end
  end

  let(:modal_id) { Admin::Import::Jira::ImportRuns::SelectProjects::ModalComponent::MODAL_ID }
  let(:filter_label) { I18n.t(:"admin.jira.run.wizard.select_dialog.filter_projects") }

  before do
    allow(Import::JiraInstanceMetaDataJob).to receive(:perform_later)
    allow(Import::JiraProjectsMetaDataJob).to receive(:perform_later)
    allow(Import::JiraFetchAndImportProjectsJob).to receive(:perform_later)
    allow(Import::JiraRevertImportJob).to receive(:perform_later).and_return(double(job_id: "job-stub"))
    allow(Import::JiraFinalizeImportJob).to receive(:perform_later)
    visit admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id)
  end

  def open_select_projects_modal
    click_on I18n.t(:"admin.jira.run.wizard.sections.import_scope.button_select")
    expect(page).to have_css("##{modal_id}[open]")
  end

  # Primer IconButton moves `aria-label` to a hidden `<tool-tip>` web component
  # and sets `aria-labelledby` on the button. Find the button via the tooltip's `for` attribute.
  def pagination_button_for(label)
    tooltip = find("tool-tip", text: label, visible: :all)
    find("[id='#{tooltip[:for]}']")
  end

  # `fill_in with: ""` does not fire an `input` event in Cuprite (Ferrum skips
  # the type step for empty strings). Dispatch the event manually so the
  # debounced filter Stimulus action picks it up.
  def clear_filter
    find("[name='filter']").set("")
    page.execute_script("document.querySelector('[name=\"filter\"]').dispatchEvent(new Event('input', {bubbles:true}))")
  end

  it "opens dialog showing all projects unchecked, with title and key captions" do
    open_select_projects_modal

    expect(page).to have_text(I18n.t(:"admin.jira.run.wizard.select_projects.title"))
    expect(page).to have_field("Project Alpha", type: :checkbox, checked: false)
    expect(page).to have_field("Project Beta", type: :checkbox, checked: false)
    expect(page).to have_field("Gamma Project", type: :checkbox, checked: false)
    within("##{modal_id}") do
      expect(page).to have_text("ALPHA")
      expect(page).to have_text("BETA")
      expect(page).to have_text("GAMMA")
    end
  end

  it "restores previously saved selection when opening" do
    jira_import.update!(projects: [{ "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" }])
    visit admin_import_jira_run_path(jira_id: jira.id, id: jira_import.id)
    open_select_projects_modal

    expect(page).to have_field("Project Alpha", checked: true)
    expect(page).to have_field("Project Beta", checked: false)
  end

  describe "filtering" do
    before { open_select_projects_modal }

    it "filters by name, key, and case; shows a no-results notice; and clears back to the full list" do
      fill_in filter_label, with: "Alpha"
      expect(page).to have_field("Project Alpha")
      expect(page).to have_no_field("Project Beta")
      expect(page).to have_no_field("Gamma Project")

      fill_in filter_label, with: "BETA"
      expect(page).to have_field("Project Beta")
      expect(page).to have_no_field("Project Alpha")

      fill_in filter_label, with: "gamma"
      expect(page).to have_field("Gamma Project")
      expect(page).to have_no_field("Project Alpha")

      fill_in filter_label, with: "ZZNOTFOUND"
      expect(page).to have_css(".op-toast.-info")
      expect(page).to have_no_field("Project Alpha")

      clear_filter
      expect(page).to have_field("Project Alpha")
      expect(page).to have_field("Project Beta")
      expect(page).to have_field("Gamma Project")
    end
  end

  describe "bulk selection" do
    before { open_select_projects_modal }

    it "checks and unchecks all visible projects" do
      click_on I18n.t(:button_check_all)
      expect(page).to have_field("Project Alpha", checked: true)
      expect(page).to have_field("Project Beta", checked: true)
      expect(page).to have_field("Gamma Project", checked: true)

      click_on I18n.t(:button_uncheck_all)
      expect(page).to have_field("Project Alpha", checked: false)
      expect(page).to have_field("Project Beta", checked: false)
      expect(page).to have_field("Gamma Project", checked: false)
    end

    it "scopes bulk check and uncheck to visible filtered projects" do
      fill_in filter_label, with: "Alpha"
      expect(page).to have_no_field("Project Beta")
      click_on I18n.t(:button_check_all)
      clear_filter
      expect(page).to have_field("Project Alpha", checked: true)
      expect(page).to have_field("Project Beta", checked: false)
      expect(page).to have_field("Gamma Project", checked: false)

      click_on I18n.t(:button_check_all)
      fill_in filter_label, with: "Alpha"
      expect(page).to have_no_field("Project Beta")
      click_on I18n.t(:button_uncheck_all)
      clear_filter
      expect(page).to have_field("Project Alpha", checked: false)
      expect(page).to have_field("Project Beta", checked: true)
      expect(page).to have_field("Gamma Project", checked: true)
    end
  end

  describe "individual selection" do
    before { open_select_projects_modal }

    it "tracks the selection counter and shows the submit button once all requests drain" do
      check "Project Alpha"
      within("[data-admin--jira-projects-target='submitButton']") do
        expect(page).to have_text("1")
      end

      check "Project Beta"
      check "Gamma Project"
      expect(page).to have_css("[data-admin--jira-projects-target='submitButton']:not([hidden])")
      expect(page).to have_css("[data-admin--jira-projects-target='spinnerButton'][hidden]", visible: :all)

      uncheck "Project Beta"
      within("[data-admin--jira-projects-target='submitButton']") do
        expect(page).to have_text("2")
      end
    end
  end

  describe "confirming selection" do
    before { open_select_projects_modal }

    it "saves the selected projects, closes the dialog, and updates the wizard button count" do
      check "Project Alpha"
      check "Project Beta"

      within("[data-admin--jira-projects-target='submitButton']") do
        click_on I18n.t(:button_continue)
      end

      expect(page).to have_no_css("##{modal_id}[open]")
      expect(jira_import.reload.projects).to contain_exactly(
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" }
      )
      expect(page).to have_css("[data-controller='async-dialog']", text: "2")
    end

    it "discards changes when cancelled" do
      check "Project Alpha"
      click_on I18n.t(:button_cancel)
      expect(page).to have_no_css("##{modal_id}[open]")
      expect(jira_import.reload.projects).to be_empty
    end
  end

  describe "pagination" do
    let(:available_projects) do
      (1..25).map { |i| { "id" => (10_000 + i).to_s, "name" => "Project #{i.to_s.rjust(2, '0')}", "key" => "PROJ#{i}" } }
    end

    before { open_select_projects_modal }

    it "paginates results, disables nav at page boundaries, and preserves selections across pages" do
      expect(page).to have_text("1 / 2")
      expect(pagination_button_for(I18n.t(:label_previous))).to be_disabled
      expect(page).to have_field("Project 01")
      expect(page).to have_no_field("Project 21")

      check "Project 01"
      pagination_button_for(I18n.t(:label_next)).click

      expect(page).to have_text("2 / 2")
      expect(pagination_button_for(I18n.t(:label_next))).to be_disabled
      expect(page).to have_field("Project 21")
      expect(page).to have_no_field("Project 01")

      check "Project 21"
      pagination_button_for(I18n.t(:label_previous)).click

      expect(page).to have_text("1 / 2")
      expect(page).to have_field("Project 01", checked: true)
      expect(page).to have_no_field("Project 21")
      within("[data-admin--jira-projects-target='submitButton']") do
        expect(page).to have_text("2")
      end
    end
  end
end
