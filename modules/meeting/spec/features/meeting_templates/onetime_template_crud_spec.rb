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

RSpec.describe "Onetime templates CRUD", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }

  before { login_as(admin) }

  describe "viewing templates index" do
    context "with existing templates" do
      shared_let(:onetime_template1) { create(:onetime_template, project:, title: "Template 1") }
      shared_let(:onetime_template2) { create(:onetime_template, project: other_project, title: "Template 2") }
      shared_let(:recurring_meeting) { create(:recurring_meeting, project:) }
      shared_let(:series_template) { recurring_meeting.template }
      shared_let(:regular_meeting) { create(:meeting, template: false, project:, title: "Regular meeting") }

      before { visit templates_meetings_path }

      it "shows all onetime templates" do
        page.within("#content") do
          expect(page).to have_text("Template 1")
          expect(page).to have_text("Template 2")
          expect(page).to have_no_text(series_template.title)
          expect(page).to have_no_text("Regular meeting")
          expect(page).to have_text(project.name)
          expect(page).to have_text(other_project.name)
        end

        within_row("Template 1") do
          expect(page).to have_css('[data-test-selector="more-button"]')
        end
      end
    end

    context "with no templates" do
      before do
        Meeting.onetime_templates.destroy_all
        visit templates_meetings_path
      end

      it "shows blank slate" do
        expect(page).to have_css(".blankslate", text: "There are no templates to display")
      end
    end

    context "with project-scoped index" do
      shared_let(:project_template) { create(:onetime_template, project:, title: "Project template") }
      shared_let(:other_template) { create(:onetime_template, project: other_project, title: "Other template") }

      before { visit templates_project_meetings_path(project) }

      it "shows only project templates" do
        expect(page).to have_text("Project template")
        expect(page).to have_no_text("Other template")
      end
    end
  end

  describe "creating onetime templates" do
    context "without enterprise token" do
      before { visit templates_meetings_path }

      it "does not show the create template button" do
        expect(page).to have_no_css("#add-template-button")
      end
    end
  end

  describe "creating onetime templates", with_ee: [:meeting_templates] do
    include Components::Autocompleter::NgSelectAutocompleteHelpers

    context "when creating from global templates page" do
      before { visit templates_meetings_path }

      it "can create a template" do
        find_by_id("add-template-button").click

        expect(page).to have_dialog("New template")

        within_dialog "New template" do
          select_autocomplete find('[data-test-selector="project_id"]'),
                              query: project.name,
                              results_selector: "body"

          click_button "Create template"
        end

        wait_for_network_idle

        template = Meeting.last

        expect(template.template).to be true
        expect(template.recurring_meeting_id).to be_nil
        expect(template.project).to eq(project)
        expect(template.title).to eq(I18n.t(:label_meeting_template_new))

        expect(page).to have_current_path(project_meeting_path(project, template))
      end
    end

    context "when creating from project templates page" do
      before { visit templates_project_meetings_path(project) }

      it "can create a template with a preselected project" do
        find_by_id("add-template-button").click

        wait_for_network_idle

        template = Meeting.last

        expect(template.template).to be true
        expect(template.recurring_meeting_id).to be_nil
        expect(template.project).to eq(project)
        expect(template.title).to eq(I18n.t(:label_meeting_template_new))

        expect(page).to have_current_path(project_meeting_path(project, template))
      end
    end
  end

  describe "editing onetime templates" do
    let!(:template) { create(:onetime_template, project:, title: "Original title") }

    before do
      visit templates_meetings_path
    end

    it "can navigate to edit view via more menu" do
      within_row("Original title") do
        find('[data-test-selector="more-button"]').click
      end

      click_link_or_button "Edit template"

      # Should navigate to the meeting show page (templates don't have a separate edit path)
      expect(page).to have_current_path(project_meeting_path(project, template))
    end
  end

  describe "deleting onetime templates" do
    let!(:template_to_delete) { create(:onetime_template, project:, title: "Template to delete") }

    before do
      visit templates_meetings_path
    end

    it "can delete template via more menu" do
      within_row("Template to delete") do
        find('[data-test-selector="more-button"]').click
      end

      click_link_or_button "Delete template"

      expect(page).to have_dialog("Delete template")

      within_dialog "Delete template" do
        click_button "Delete"
      end

      wait_for_network_idle

      expect(page).to have_current_path(templates_project_meetings_path(project))
      expect(page).to have_no_text("Template to delete")
      expect(Meeting.exists?(template_to_delete.id)).to be false
    end
  end

  describe "permissions" do
    shared_let(:permissions_template) { create(:onetime_template, project:, title: "Permission test template") }

    context "as user with view_meetings only" do
      let(:user_view_only) do
        create(:user, member_with_permissions: { project => [:view_meetings] })
      end

      before do
        logout
        login_as(user_view_only)
        visit templates_meetings_path
      end

      it "sees a 403 error" do
        expect(page).to have_text("You are not authorized to access this page.")
      end
    end

    context "as user with create_meetings permission" do
      let(:user_with_create) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] })
      end

      before do
        logout
        login_as(user_with_create)
        visit templates_meetings_path
      end

      it "can access templates page and see templates" do
        expect(page).to have_text("Permission test template")
      end
    end

    context "as user with edit_meetings permission" do
      let(:user_with_edit) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] })
      end

      before do
        logout
        login_as(user_with_edit)
        visit templates_meetings_path
      end

      it "can see edit action in menu but not delete or create button" do
        expect(page).to have_no_css("#add-template-button")

        within_row("Permission test template") do
          find('[data-test-selector="more-button"]').click
        end

        expect(page).to have_link("Edit template")
        expect(page).to have_no_link("Delete template")
      end
    end

    context "as user with delete_meetings permission" do
      let(:user_with_delete) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings delete_meetings] })
      end

      before do
        logout
        login_as(user_with_delete)
        visit templates_meetings_path
      end

      it "can see delete action in menu but not edit or create button" do
        expect(page).to have_no_css("#add-template-button")

        within_row("Permission test template") do
          find('[data-test-selector="more-button"]').click
        end

        expect(page).to have_link("Delete template")
        expect(page).to have_no_link("Edit template")
      end
    end

    context "as user with both edit and delete permissions" do
      let(:user_with_both) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings] })
      end

      before do
        logout
        login_as(user_with_both)
        visit templates_meetings_path
      end

      it "can see both edit and delete actions in menu" do
        within_row("Permission test template") do
          find('[data-test-selector="more-button"]').click
        end

        expect(page).to have_link("Edit template")
        expect(page).to have_link("Delete template")
      end
    end
  end

  describe "adding agenda items to a template" do
    let(:template) { create(:onetime_template, project:, title: "My template") }
    let(:show_page) { Pages::Meetings::Show.new(template) }

    before { show_page.visit! }

    it "does not show or save a presenter" do
      show_page.add_agenda_item do
        expect(page).to have_no_css("label", text: "Presenter")

        fill_in "Title", with: "Introduction"
      end

      wait_for_network_idle

      show_page.expect_agenda_item title: "Introduction"
      expect(MeetingAgendaItem.last.presenter).to be_nil
    end
  end

  def within_row(title, &)
    template_link = page.find("a", text: title)

    row = template_link.ancestor('[role="row"]')

    within(row, &)
  end
end
