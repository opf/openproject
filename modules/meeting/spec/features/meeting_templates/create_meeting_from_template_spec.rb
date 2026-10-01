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

require_relative "../../support/pages/meetings/show"
require_relative "../../support/pages/meetings/index"

RSpec.describe "Create meeting from template", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }

  let(:meetings_page) { Pages::Meetings::Index.new(project:) }
  let(:show_page) { Pages::Meetings::Show.new(Meeting.last) }

  before { login_as(admin) }

  describe "creating meeting from template using template selector" do
    context "without enterprise token" do
      let!(:template) { create(:onetime_template, project:, title: "Standup Template") }

      before { meetings_page.visit! }

      it "does not show template selector in the new meeting dialog" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        expect(page).to have_dialog("New one-time meeting")

        within_dialog "New one-time meeting" do
          expect(page).to have_no_css('[data-test-selector="template_id"]')
        end
      end
    end
  end

  describe "creating meeting from template using template selector", with_ee: [:meeting_templates] do
    context "with templates in project" do
      let!(:template) do
        create(:onetime_template, project:, title: "Standup Template").tap do |t|
          create(:meeting_agenda_item, meeting: t, title: "Updates")
          create(:meeting_agenda_item, meeting: t, title: "Blockers")
          create(:meeting_agenda_item, meeting: t, title: "Next steps")
        end
      end

      let!(:other_template) do
        create(:onetime_template, project:, title: "Retro Template").tap do |t|
          create(:meeting_agenda_item, meeting: t, title: "What went well")
          create(:meeting_agenda_item, meeting: t, title: "What to improve")
        end
      end

      before do
        meetings_page.visit!
      end

      it "can create a meeting from a template with agenda items copied" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        expect(page).to have_dialog("New one-time meeting")

        within_dialog "New one-time meeting" do
          expect(page).to have_css('[data-test-selector="template_id"]')

          select_autocomplete find('[data-test-selector="template_id"]'),
                              query: "Standup",
                              select_text: "Standup Template",
                              results_selector: "body"

          fill_in "Title", with: "Tomorrow's standup"

          click_button "Create"
        end

        wait_for_network_idle

        meeting = Meeting.last

        expect(meeting.template).to be false
        expect(meeting.title).to eq("Tomorrow's standup")

        expect(meeting.agenda_items.count).to eq(3)

        expect(page).to have_text("Updates")
        expect(page).to have_text("Blockers")
        expect(page).to have_text("Next steps")
      end

      it "can create a meeting without selecting a template" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        expect(page).to have_dialog("New one-time meeting")

        within_dialog "New one-time meeting" do
          expect(page).to have_css('[data-test-selector="template_id"]')

          fill_in "Title", with: "Non template meeting"

          click_button "Create"
        end

        wait_for_network_idle

        meeting = Meeting.last
        expect(meeting.template).to be false
        expect(meeting.title).to eq("Non template meeting")
        expect(meeting.agenda_items.count).to eq(0)
      end

      it "shows all project templates in autocompleter" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        within_dialog "New one-time meeting" do
          find('[data-test-selector="template_id"]').click

          expect(page).to have_text("Standup Template")
          expect(page).to have_text("Retro Template")
        end
      end
    end

    context "with no templates in project" do
      before do
        Meeting.onetime_templates.where(project:).destroy_all
        meetings_page.visit!
      end

      it "does not show template selector when no templates exist" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        expect(page).to have_dialog("New one-time meeting")

        within_dialog "New one-time meeting" do
          expect(page).to have_no_css('[data-test-selector="template_id"]')
        end
      end
    end

    context "with templates from other project" do
      let!(:current_project_template) do
        create(:onetime_template, project:, title: "Current project template")
      end

      let!(:other_project_template) do
        create(:onetime_template, project: other_project, title: "Other project template")
      end

      before do
        meetings_page.visit!
      end

      it "only shows templates from current project" do
        meetings_page.click_on "add-meeting-button"
        meetings_page.click_on "One-time"

        within_dialog "New one-time meeting" do
          find('[data-test-selector="template_id"]').click

          expect(page).to have_text("Current project template")

          expect(page).to have_no_text("Other project template")
        end
      end
    end
  end

  describe "creating meeting from template using template selector from global index", with_ee: [:meeting_templates] do
    let(:global_meetings_page) { Pages::Meetings::Index.new(project: nil) }
    let(:template) { create(:onetime_template, project:, title: "Template") }

    before do
      global_meetings_page.visit!
    end

    it "shows a template selector when user has access to templates" do
      template

      global_meetings_page.click_on "add-meeting-button"
      global_meetings_page.click_on "One-time"

      expect(page).to have_dialog("New one-time meeting")

      # Initially disabled
      within_dialog "New one-time meeting" do
        expect(page).to have_css('[data-test-selector="template_id"]', text: "Select a project first")
      end

      # Disabled when a project with no accessible templates is selected
      wait_for_turbo_stream do
        global_meetings_page.set_project(other_project)
      end

      within_dialog "New one-time meeting" do
        expect(page).to have_css('[data-test-selector="template_id"]', text: "No templates available for this project")
      end

      # Enabled when a project with accessible templates is selected
      wait_for_turbo_stream do
        global_meetings_page.set_project(project)
      end

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(template.title)
      end
    end

    it "shows no template selector when user has access to no templates" do
      global_meetings_page.click_on "add-meeting-button"
      global_meetings_page.click_on "One-time"

      expect(page).to have_dialog("New one-time meeting")

      within_dialog "New one-time meeting" do
        expect(page).to have_no_css('[data-test-selector="template_id"]')
      end
    end

    it "keeps the template selector visible with the template preselected on failed submission" do
      template

      global_meetings_page.click_on "add-meeting-button"
      global_meetings_page.click_on "One-time"

      expect(page).to have_dialog("New one-time meeting")

      wait_for_turbo_stream do
        global_meetings_page.set_project(project)
      end

      within_dialog "New one-time meeting" do
        select_autocomplete find('[data-test-selector="template_id"]'),
                            query: template.title,
                            select_text: template.title,
                            results_selector: "body"

        # Submit without a title to trigger validation failure
        wait_for_turbo_stream do
          click_button "Create"
        end
      end

      within_dialog "New one-time meeting" do
        expect(page).to have_text("Title can't be blank.")

        # Template selector must still be visible with the previously selected template preselected
        expect(page).to have_css('[data-test-selector="template_id"]', text: template.title)
      end
    end
  end

  describe "creating meeting from template using 'Create from template' button" do
    context "without enterprise token" do
      let!(:template) { create(:onetime_template, project:, title: "Planning template") }

      let(:template_show_page) { Pages::Meetings::Show.new(template) }

      before { template_show_page.visit! }

      it "does not show '+ Meeting' button" do
        expect(page).to have_no_link(id: "create-meeting-from-template")
      end
    end
  end

  describe "creating meeting from template using 'Create from template' button", with_ee: [:meeting_templates] do
    let!(:template) do
      create(:onetime_template, project:, title: "Planning template").tap do |t|
        create(:meeting_agenda_item, meeting: t, title: "Goals")
        create(:meeting_agenda_item, meeting: t, title: "Tasks")
        create(:meeting_agenda_item, meeting: t, title: "Timeline")
      end
    end

    let(:template_show_page) { Pages::Meetings::Show.new(template) }

    before do
      template_show_page.visit!
    end

    it "can create a meeting from template page with button" do
      expect(page).to have_link(id: "create-meeting-from-template")
      click_link(id: "create-meeting-from-template")

      expect(page).to have_dialog("New one-time meeting")

      within_dialog "New one-time meeting" do
        expect(page).to have_no_css('[data-test-selector="template_id"]')

        fill_in "Title", with: "Sprint planning"

        click_button "Create"
      end

      wait_for_network_idle

      meeting = Meeting.last
      expect(meeting.template).to be false
      expect(meeting.title).to eq("Sprint planning")

      expect(meeting.agenda_items.count).to eq(3)

      expect(page).to have_text("Goals")
      expect(page).to have_text("Tasks")
      expect(page).to have_text("Timeline")
    end
  end

  describe "permissions" do
    let!(:template) do
      create(:onetime_template,
             project:,
             title: "Permission test template")
    end

    context "as user with view_meetings only" do
      let(:user_view_only) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end

      before do
        logout
        login_as(user_view_only)
        visit project_meeting_path(project, template)
      end

      it "does not show the '+ Meeting' button" do
        expect(page).to have_no_link(id: "create-meeting-from-template")
      end
    end

    context "as user with create_meetings permission", with_ee: [:meeting_templates] do
      let(:user_with_create) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] })
      end

      before do
        logout
        login_as(user_with_create)
        visit project_meeting_path(project, template)
      end

      it "shows the '+ Meeting' button" do
        expect(page).to have_link(id: "create-meeting-from-template")
      end
    end
  end

  describe "autocompleter labels and ordering", with_ee: [:meeting_templates] do
    let(:project_a) { create(:project, name: "Project A", enabled_module_names: %i[meetings]) }
    let(:project_b) { create(:project, name: "Project B", enabled_module_names: %i[meetings]) }

    let!(:template_a1) { create(:onetime_template, project: project_a, title: "Template A1") }
    let!(:template_a2) { create(:onetime_template, project: project_a, title: "Template A2") }
    let!(:template_b1) { create(:onetime_template, project: project_b, title: "Template A1", sharing: :system) }

    let(:project_a_meetings_page) { Pages::Meetings::Index.new(project: project_a) }

    before { project_a_meetings_page.visit! }

    it "prefixes templates from other projects with their project name" do
      project_a_meetings_page.click_on "add-meeting-button"
      project_a_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click

        expect(page).to have_text("Template A1")
        expect(page).to have_text("Template A2")
        expect(page).to have_text("Project B: Template A1")
      end
    end

    it "orders options such that all templates from a project are grouped together" do
      project_a_meetings_page.click_on "add-meeting-button"
      project_a_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click

        expect(all(".ng-option").map(&:text)).to eq(["Template A1", "Template A2", "Project B: Template A1"])
      end
    end
  end
end
