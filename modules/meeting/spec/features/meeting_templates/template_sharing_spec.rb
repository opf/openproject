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

RSpec.describe "Template sharing", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:template) { create(:onetime_template, project:, title: "My template", sharing: :none) }

  let(:show_page) { Pages::Meetings::Show.new(template) }

  context "as user with edit_meetings permission" do
    shared_let(:editor) do
      create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] })
    end

    before do
      login_as editor
      show_page.visit!
    end

    it "shows the sharing section in the sidebar" do
      expect(page).to have_text(I18n.t(:label_meeting_template_sharing))
      expect(page).to have_text(I18n.t(:label_meeting_template_sharing_none))
    end

    it "can change sharing to subprojects" do
      within("#meetings-side-panel-sharing-component") do
        click_button I18n.t(:label_meeting_template_sharing_none)
        click_link_or_button I18n.t(:label_meeting_template_sharing_descendants)
      end

      wait_for_network_idle

      expect(page).to have_text(I18n.t(:label_meeting_template_sharing_descendants))
      expect(template.reload.sharing).to eq("descendants")
    end

    it "can change sharing to all projects" do
      within("#meetings-side-panel-sharing-component") do
        click_button I18n.t(:label_meeting_template_sharing_none)
        click_link_or_button I18n.t(:label_meeting_template_sharing_system)
      end

      wait_for_network_idle

      expect(page).to have_text(I18n.t(:label_meeting_template_sharing_system))
      expect(template.reload.sharing).to eq("system")
    end

    it "can change sharing back to only this project" do
      template.update!(sharing: :descendants)
      show_page.visit!

      within("#meetings-side-panel-sharing-component") do
        click_button I18n.t(:label_meeting_template_sharing_descendants)
        click_link_or_button I18n.t(:label_meeting_template_sharing_none)
      end

      wait_for_network_idle

      expect(page).to have_text(I18n.t(:label_meeting_template_sharing_none))
      expect(template.reload.sharing).to eq("none")
    end
  end

  context "as user with view_meetings only" do
    shared_let(:viewer) do
      create(:user, member_with_permissions: { project => %i[view_meetings] })
    end

    before do
      login_as viewer
      show_page.visit!
    end

    it "does not show the sharing section" do
      expect(page).to have_no_css("#meetings-side-panel-sharing-component")
    end
  end

  # Happy path
  context "when sharing level is changed", with_ee: [:meeting_templates] do
    shared_let(:child_project) { create(:project, enabled_module_names: %i[meetings], parent: project) }
    shared_let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_meetings edit_meetings],
               child_project => %i[view_meetings create_meetings]
             })
    end

    let(:child_meetings_page) { Pages::Meetings::Index.new(project: child_project) }

    before { login_as user }

    it "toggles visibility in child project's new meeting form" do
      # Template not visible before sharing change
      child_meetings_page.visit!
      child_meetings_page.click_on "add-meeting-button"
      child_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        expect(page).to have_no_css('[data-test-selector="template_id"]')
      end

      # Change sharing to descendants
      visit project_meeting_path(project, template)

      within("#meetings-side-panel-sharing-component") do
        click_button I18n.t(:label_meeting_template_sharing_none)
        click_link_or_button I18n.t(:label_meeting_template_sharing_descendants)
      end

      wait_for_network_idle

      expect(template.reload.sharing).to eq("descendants")

      # Template is now visible in child project form
      child_meetings_page.visit!
      child_meetings_page.click_on "add-meeting-button"
      child_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(template.title)
      end
    end
  end

  context "with templates shared via :descendants to a user with child-only access", with_ee: [:meeting_templates] do
    shared_let(:parent_project) { create(:project, enabled_module_names: %i[meetings]) }
    shared_let(:child_project) { create(:project, enabled_module_names: %i[meetings], parent: parent_project) }
    shared_let(:user) do
      create(:user, member_with_permissions: { child_project => %i[view_meetings create_meetings] })
    end
    shared_let(:descendants_template) do
      create(:onetime_template, project: parent_project, title: "Parent template", sharing: :descendants)
    end

    let(:child_meetings_page) { Pages::Meetings::Index.new(project: child_project) }
    let(:global_meetings_page) { Pages::Meetings::Index.new(project: nil) }

    before { login_as user }

    it "shows the template when creating a meeting from the child project" do
      child_meetings_page.visit!
      child_meetings_page.click_on "add-meeting-button"
      child_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(descendants_template.title)
      end
    end

    it "shows the template selector and template when creating from the global index" do
      global_meetings_page.visit!
      global_meetings_page.click_on "add-meeting-button"
      global_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        expect(page).to have_css('[data-test-selector="template_id"]', text: "Select a project first")
      end

      global_meetings_page.set_project(child_project)
      wait_for_network_idle

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(descendants_template.title)
      end
    end
  end

  context "with a :system template from a project the user has no access to", with_ee: [:meeting_templates] do
    shared_let(:accessible_project) { create(:project, enabled_module_names: %i[meetings]) }
    shared_let(:inaccessible_project) { create(:project, enabled_module_names: %i[meetings]) }
    shared_let(:user) do
      create(:user, member_with_permissions: { accessible_project => %i[view_meetings create_meetings] })
    end
    shared_let(:system_template) do
      create(:onetime_template, project: inaccessible_project, title: "System template", sharing: :system)
    end

    let(:accessible_meetings_page) { Pages::Meetings::Index.new(project: accessible_project) }
    let(:global_meetings_page) { Pages::Meetings::Index.new(project: nil) }

    before { login_as user }

    it "shows the system template when creating from an accessible project" do
      accessible_meetings_page.visit!
      accessible_meetings_page.click_on "add-meeting-button"
      accessible_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(system_template.title)
      end
    end

    it "shows the template selector and system template when creating from the global index" do
      global_meetings_page.visit!
      global_meetings_page.click_on "add-meeting-button"
      global_meetings_page.click_on "One-time"

      within_dialog "New one-time meeting" do
        expect(page).to have_css('[data-test-selector="template_id"]', text: "Select a project first")
      end

      global_meetings_page.set_project(accessible_project)
      wait_for_network_idle

      within_dialog "New one-time meeting" do
        find('[data-test-selector="template_id"]').click
        expect(page).to have_text(system_template.title)
      end
    end
  end
end
