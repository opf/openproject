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
require_relative "../../support/pages/work_package_meetings_tab"
require_relative "../../support/pages/structured_meeting/show"

RSpec.describe "Open the Meetings tab", :js do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, subject: "A test work_package") }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_meetings
                           edit_meetings
                           manage_agendas))
  end
  let(:meetings_tab) { Pages::MeetingsTab.new(work_package.id) }

  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }
  let(:meetings_tab_element) { find(".op-tab-row--link_selected", text: "MEETINGS") }

  shared_context "a meetings tab" do
    before do
      login_as(user)
    end

    it "shows the meetings tab when the user is allowed to see it" do
      work_package_page.visit!
      work_package_page.switch_to_tab(tab: "meetings")

      meetings_tab.expect_tab_content_rendered
    end

    context "when the user does not have the permissions to see the meetings tab" do
      let(:role) do
        create(:project_role,
               permissions: %i(view_work_packages))
      end

      it "does not show the meetings tab" do
        work_package_page.visit!

        meetings_tab.expect_tab_not_present
      end

      context "when the user has permission in another project" do
        let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }

        let(:user) do
          create(:user,
                 member_with_roles: { project => role },
                 member_with_permissions: {
                   other_project => %i(view_work_packages view_meetings)
                 })
        end

        it "does show the tab" do
          work_package_page.visit!

          meetings_tab.expect_tab_present
        end
      end
    end

    context "when the user has the permission to see the tab, but the work package is linked in two projects" do
      let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }
      let!(:visible_meeting) { create(:structured_meeting, project:) }
      let!(:invisible_meeting) { create(:structured_meeting, project: other_project) }

      let!(:meeting_agenda_item_of_visible_meeting) do
        create(:meeting_agenda_item, meeting: visible_meeting, work_package:, notes: "Public note!")
      end

      let!(:meeting_agenda_item_of_invisible_meeting) do
        create(:meeting_agenda_item, meeting: invisible_meeting, work_package:, notes: "Private note")
      end

      let(:role) do
        create(:project_role,
               permissions: %i(view_work_packages view_meetings))
      end

      it "shows the one visible meeting" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_tab_count(1)
        meetings_tab.expect_upcoming_counter_to_be(1)
        meetings_tab.expect_past_counter_to_be(0)

        page.within_test_selector("op-meeting-container-#{visible_meeting.id}") do
          expect(page).to have_content(visible_meeting.title)
          expect(page).to have_content(meeting_agenda_item_of_visible_meeting.notes)

          expect(page).to have_no_content(invisible_meeting.title)
          expect(page).to have_no_content(meeting_agenda_item_of_invisible_meeting.notes)
        end
      end
    end

    context "when the meetings module is not enabled for the project" do
      before do
        project.enabled_module_names = ["work_package_tracking"]
        project.save!
      end

      it "does not show the meetings tab" do
        work_package_page.visit!

        meetings_tab.expect_tab_not_present
      end

      context "when the user has permission to view in another project" do
        let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }

        let(:user) do
          create(:user,
                 member_with_permissions: {
                   project => %i(view_work_packages),
                   other_project => %i(view_work_packages view_meetings)
                 })
        end

        it "does show the tab, but does not show the button" do
          work_package_page.visit!

          meetings_tab.expect_tab_present
          switch_to_meetings_tab
          meetings_tab.expect_add_to_meeting_button_not_present
        end
      end

      context "when the user has permission to manage in another project" do
        let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }

        let(:user) do
          create(:user,
                 member_with_permissions: {
                   project => %i(view_work_packages),
                   other_project => %i(view_work_packages view_meetings manage_agendas)
                 })
        end

        it "does show the tab and shows the add button" do
          work_package_page.visit!

          meetings_tab.expect_tab_present
          switch_to_meetings_tab
          meetings_tab.expect_add_to_meeting_button_present
        end
      end
    end

    context "when the work_package is not referenced in an upcoming meeting" do
      it "shows an empty message within the upcoming meetings section" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(0)

        expect(page).to have_content("This work package is not scheduled in an upcoming meeting agenda yet.")
      end
    end

    context "when the work_package is not referenced in a past meeting" do
      it "shows an empty message within the past meetings section" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_past_counter_to_be(0)
        meetings_tab.switch_to_past_meetings_section

        expect(page).to have_content("This work package was not mentioned in a past meeting.")
      end
    end

    context "when the work_package is already referenced in upcoming meetings" do
      let!(:first_meeting) { create(:structured_meeting, project:) }
      let!(:second_meeting) { create(:structured_meeting, project:) }

      let!(:first_meeting_agenda_item_of_first_meeting) do
        create(:meeting_agenda_item, meeting: first_meeting, work_package:, notes: "A very important note in first meeting!")
      end
      let!(:second_meeting_agenda_item_of_first_meeting) do
        create(:meeting_agenda_item, meeting: first_meeting, work_package:,
                                     notes: "Another very important note in the first meeting!")
      end
      let!(:meeting_agenda_item_of_second_meeting) do
        create(:meeting_agenda_item, meeting: second_meeting, work_package:,
                                     notes: "A very important note in the second meeting!")
      end

      it "shows the meeting agenda items in the upcoming meetings section grouped by meeting" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(2)
        meetings_tab.expect_past_counter_to_be(0)

        page.within_test_selector("op-meeting-container-#{first_meeting.id}") do
          expect(page).to have_content(first_meeting.title)
          expect(page).to have_content(first_meeting_agenda_item_of_first_meeting.notes)
          expect(page).to have_content(second_meeting_agenda_item_of_first_meeting.notes)
        end

        page.within_test_selector("op-meeting-container-#{second_meeting.id}") do
          expect(page).to have_content(second_meeting.title)
          expect(page).to have_content(meeting_agenda_item_of_second_meeting.notes)
        end

        meeting_containers = page.all("[data-test-selector^='op-meeting-container-']")
        expect(meeting_containers[0]["data-test-selector"]).to eq("op-meeting-container-#{first_meeting.id}")
        expect(meeting_containers[1]["data-test-selector"]).to eq("op-meeting-container-#{second_meeting.id}")
      end
    end

    context "when the work_package was already referenced in past meetings" do
      let!(:first_past_meeting) { create(:structured_meeting, project:, start_time: Date.yesterday - 11.hours) }
      let!(:second_past_meeting) { create(:structured_meeting, project:, start_time: Date.yesterday - 10.hours) }

      let!(:first_meeting_agenda_item_of_first_past_meeting) do
        create(:meeting_agenda_item, meeting: first_past_meeting, work_package:, notes: "A very important note in first meeting!")
      end
      let!(:second_meeting_agenda_item_of_first_past_meeting) do
        create(:meeting_agenda_item, meeting: first_past_meeting, work_package:,
                                     notes: "Another very important note in the first meeting!")
      end
      let!(:meeting_agenda_item_of_second_past_meeting) do
        create(:meeting_agenda_item, meeting: second_past_meeting, work_package:,
                                     notes: "A very important note in the second meeting!")
      end

      it "shows the meeting agenda items in the past meetings section grouped by meeting" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(0)
        meetings_tab.expect_past_counter_to_be(2)

        meetings_tab.switch_to_past_meetings_section

        page.within_test_selector("op-meeting-container-#{second_past_meeting.id}") do
          expect(page).to have_content(second_past_meeting.title)
          expect(page).to have_content(meeting_agenda_item_of_second_past_meeting.notes)
        end

        page.within_test_selector("op-meeting-container-#{first_past_meeting.id}") do
          expect(page).to have_content(first_past_meeting.title)
          expect(page).to have_content(first_meeting_agenda_item_of_first_past_meeting.notes)
          expect(page).to have_content(second_meeting_agenda_item_of_first_past_meeting.notes)
        end

        meeting_containers = page.all("[data-test-selector^='op-meeting-container-']")
        expect(meeting_containers[0]["data-test-selector"]).to eq("op-meeting-container-#{second_past_meeting.id}")
        expect(meeting_containers[1]["data-test-selector"]).to eq("op-meeting-container-#{first_past_meeting.id}")
      end
    end

    context "when user is allowed to edit meetings" do
      it "shows the add to meeting button and dialog" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_add_to_meeting_button_present

        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.open_add_to_meeting_dialog
        meetings_tab.expect_add_to_meeting_dialog_shown
      end

      context "when open, upcoming meetings are visible for the user" do
        shared_let(:past_meeting) { create(:structured_meeting, project:, start_time: Date.yesterday - 10.hours) }
        shared_let(:first_upcoming_meeting) { create(:structured_meeting, project:) }
        shared_let(:second_upcoming_meeting) { create(:structured_meeting, project:) }
        shared_let(:closed_upcoming_meeting) { create(:structured_meeting, project:, state: :closed) }
        shared_let(:ongoing_meeting) do
          create(:structured_meeting, title: "Ongoing", project:, start_time: 1.hour.ago, duration: 4.0)
        end

        let(:meeting_page) { Pages::StructuredMeeting::Show.new(first_upcoming_meeting) }

        it "enables the user to add the work package to multiple open, upcoming meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.expect_upcoming_counter_to_be(0)

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            first_upcoming_meeting,
            "A very important note added from the meetings tab to the first meeting!"
          )

          meetings_tab.expect_upcoming_counter_to_be(1)

          page.within_test_selector("op-meeting-container-#{first_upcoming_meeting.id}") do
            expect(page).to have_content("A very important note added from the meetings tab to the first meeting!")
          end

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            second_upcoming_meeting,
            "A very important note added from the meetings tab to the second meeting!"
          )

          meetings_tab.expect_upcoming_counter_to_be(2)

          page.within_test_selector("op-meeting-container-#{second_upcoming_meeting.id}") do
            expect(page).to have_content("A very important note added from the meetings tab to the second meeting!")
          end
        end

        it "allows the user to select ongoing meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            ongoing_meeting,
            "Some notes to be added"
          )

          meetings_tab.expect_upcoming_counter_to_be(1)

          page.within_test_selector("op-meeting-container-#{ongoing_meeting.id}") do
            expect(page).to have_content("Some notes to be added")
          end
        end

        it "does not enable the user to select a past meeting" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          fill_in("meeting_agenda_item_meeting_id", with: past_meeting.title)
          expect(page).to have_no_css(".ng-option-marked", text: past_meeting.title)
        end

        it "does not enable the user to select a closed, upcoming meeting" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          fill_in("meeting_agenda_item_meeting_id", with: closed_upcoming_meeting.title)
          expect(page).to have_no_css(".ng-option-marked", text: closed_upcoming_meeting.title)
        end

        it "requires a meeting to be selected" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          retry_block do
            click_on("Save")

            expect(page).to have_content("Meeting can't be blank")
          end
        end

        it "adds presenter when the work package is added to a meeting" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            first_upcoming_meeting,
            "A very important note added from the meetings tab to the first meeting!"
          )

          meeting_page.visit!

          expect(page.find(".op-meeting-agenda-item--presenter")).to have_text(user.name)
        end
      end
    end

    context "when user is not allowed to edit meetings" do
      let(:restricted_role) do
        create(:project_role,
               permissions: %i(view_work_packages
                               view_meetings)) # edit_meetings is missing
      end
      let(:user) do
        create(:user,
               member_with_roles: { project => restricted_role })
      end

      it "does not show the add to meeting button" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_add_to_meeting_button_not_present
      end
    end
  end

  describe "work package full view" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

    it_behaves_like "a meetings tab"
  end

  describe "work package split view" do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "a meetings tab"
  end

  def switch_to_meetings_tab
    work_package_page.switch_to_tab(tab: "meetings")
    meetings_tab.expect_tab_content_rendered # wait for the tab to be rendered
  end
end
