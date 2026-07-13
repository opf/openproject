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
require_relative "../../support/pages/work_package_meetings_tab"
require_relative "../../support/pages/meetings/show"

RSpec.describe "Open the Meetings tab",
               :js do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, subject: "A test work_package") }

  shared_let(:role) do
    create(:project_role,
           permissions: %i(view_work_packages
                           view_meetings
                           edit_meetings
                           manage_agendas))
  end
  shared_let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let(:meetings_tab) { Pages::MeetingsTab.new(project_id: project.id, work_package_id: work_package.id) }

  let(:tabs) { Components::WorkPackages::Tabs.new(work_package) }
  let(:meetings_tab_element) { find(".op-tab-row--link_selected", text: "MEETINGS") }

  shared_context "with a meetings tab" do
    before do
      login_as(user)
    end

    it "shows the meetings tab when the user is allowed to see it" do
      work_package_page.visit!
      work_package_page.switch_to_tab(tab: "meetings")

      meetings_tab.expect_tab_content_rendered
    end

    context "when the user does not have the permissions to see the meetings tab" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i(view_work_packages) })
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
      let!(:visible_meeting) { create(:meeting, project:) }
      let!(:invisible_meeting) { create(:meeting, project: other_project) }

      let!(:meeting_agenda_item_of_visible_meeting) do
        create(:meeting_agenda_item, meeting: visible_meeting, work_package:, notes: "Public note!")
      end

      let!(:meeting_agenda_item_of_invisible_meeting) do
        create(:meeting_agenda_item, meeting: invisible_meeting, work_package:, notes: "Private note")
      end

      let(:user) do
        create(:user, member_with_permissions: { project => %i(view_work_packages view_meetings) })
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

      context "with another past meeting" do
        let!(:past_meeting) { create(:meeting, project:, start_time: 1.week.ago) }

        let!(:past_agenda_item) do
          create(:meeting_agenda_item, meeting: past_meeting, work_package:, notes: "Public note!")
        end

        it "shows both future and past meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.expect_tab_count(2)
          meetings_tab.expect_upcoming_counter_to_be(1)
          meetings_tab.expect_past_counter_to_be(1)
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

        expect(page).to have_content("This work package was not added as an agenda item in a past meeting.")
      end
    end

    context "when the work_package is already referenced in upcoming meetings" do
      let!(:first_meeting) { create(:meeting, project:) }
      let!(:second_meeting) { create(:meeting, project:) }

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

        meeting_containers = page
          .all("[data-test-selector^='op-meeting-container-']")
          .map { |container| container["data-test-selector"] }
        expect(meeting_containers).to contain_exactly("op-meeting-container-#{first_meeting.id}",
                                                      "op-meeting-container-#{second_meeting.id}")
      end
    end

    context "when the work_package is referenced and has a single outcome" do
      let!(:meeting) { create(:meeting, project:) }

      let!(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting:, work_package:, notes: "A very important note in first meeting!")
      end

      let!(:outcome) do
        create(:meeting_outcome, meeting_agenda_item:, notes: "A decision was made!")
      end

      it "shows the outcome" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(1)

        page.within_test_selector("op-meeting-container-#{meeting.id}") do
          expect(page).to have_content(meeting_agenda_item.notes)
          expect(page).to have_content(outcome.notes)
        end
      end
    end

    context "when the work_package is referenced and has multiple outcomes" do
      let!(:meeting) { create(:meeting, project:) }

      let!(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting:, work_package:, notes: "Discussion notes")
      end

      let!(:first_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, notes: "First decision")
      end

      let!(:second_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, notes: "Second decision")
      end

      let!(:third_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, notes: "Third decision")
      end

      it "shows all outcomes with numbered headings" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(1)

        page.within_test_selector("op-meeting-container-#{meeting.id}") do
          expect(page).to have_content(meeting_agenda_item.notes)
          expect(page).to have_content(first_outcome.notes)
          expect(page).to have_content(second_outcome.notes)
          expect(page).to have_content("#{I18n.t(:label_agenda_outcome)} 1")
          expect(page).to have_content("#{I18n.t(:label_agenda_outcome)} 2")
          expect(page).to have_content("#{I18n.t(:label_agenda_outcome)} 3")
        end
      end

      it "displays outcomes in ascending order of their ids" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(1)

        page.within_test_selector("op-meeting-container-#{meeting.id}") do
          outcome_containers = page.all(".outcome-container")

          expect(outcome_containers.size).to eq(3)
          expect(outcome_containers[0]).to have_content(first_outcome.notes)
          expect(outcome_containers[1]).to have_content(second_outcome.notes)
          expect(outcome_containers[2]).to have_content(third_outcome.notes)
        end
      end
    end

    context "when the work_package is linked as an outcome" do
      let!(:meeting) { create(:meeting, project:) }
      let!(:other_work_package) { create(:work_package, project:, subject: "Different work package") }

      let!(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting:, work_package: other_work_package, notes: "Discussing something else")
      end

      let!(:outcome) do
        create(:meeting_outcome, meeting_agenda_item:, work_package:, kind: :work_package)
      end

      it "shows the meeting with 'Added as outcome' label" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(1)

        page.within_test_selector("op-meeting-container-#{meeting.id}") do
          expect(page).to have_content(meeting.title)
          expect(page).to have_content(I18n.t(:label_added_as_outcome))

          expect(page).to have_no_content(meeting_agenda_item.notes)
        end
      end
    end

    context "when another work_package is linked as an outcome to this work_package's agenda item" do
      let!(:meeting) { create(:meeting, project:) }
      let!(:outcome_work_package) { create(:work_package, project:, subject: "Linked as outcome WP") }

      let!(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting:, work_package:, notes: "WP agenda item")
      end

      let!(:work_package_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, work_package: outcome_work_package, kind: :work_package)
      end

      it "shows the other work package as an outcome in the list (Bug #71038)" do
        work_package_page.visit!
        switch_to_meetings_tab

        meetings_tab.expect_upcoming_counter_to_be(1)

        page.within_test_selector("op-meeting-container-#{meeting.id}") do
          expect(page).to have_content(meeting.title)
          expect(page).to have_content(I18n.t(:label_agenda_outcome))
          expect(page).to have_content(meeting_agenda_item.notes)
          expect(page).to have_content(outcome_work_package.subject)

          expect(page).to have_no_content(I18n.t(:label_added_as_outcome))
        end
      end
    end

    context "when the work_package was already referenced in past meetings" do
      let!(:first_past_meeting) { create(:meeting, project:, start_time: Date.yesterday - 11.hours) }
      let!(:second_past_meeting) { create(:meeting, project:, start_time: Date.yesterday - 10.hours) }

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

      context "when draft, open, upcoming meetings are visible for the user" do
        shared_let(:past_meeting) { create(:meeting, project:, start_time: Date.yesterday - 10.hours) }
        shared_let(:draft_meeting) { create(:meeting, project:, state: :draft) }
        shared_let(:first_upcoming_meeting) { create(:meeting, project:) }
        shared_let(:second_upcoming_meeting) { create(:meeting, project:) }
        shared_let(:in_progress_meeting) { create(:meeting, project:, state: :in_progress) }
        shared_let(:closed_upcoming_meeting) { create(:meeting, project:, state: :closed) }
        shared_let(:ongoing_meeting) do
          create(:meeting, title: "Ongoing", project:, start_time: 1.hour.ago, duration: 4.0)
        end

        let(:meeting_page) { Pages::Meetings::Show.new(first_upcoming_meeting) }

        it "enables the user to add the work package to multiple upcoming meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.expect_upcoming_counter_to_be(0)

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            first_upcoming_meeting,
            "A very important note added from the meetings tab to the first meeting!",
            1
          )

          expect(page).to have_test_selector(
            "op-meeting-container-#{first_upcoming_meeting.id}",
            text: "A very important note added from the meetings tab to the first meeting!"
          )

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            second_upcoming_meeting,
            "A very important note added from the meetings tab to the second meeting!",
            2
          )

          expect(page).to have_test_selector(
            "op-meeting-container-#{second_upcoming_meeting.id}",
            text: "A very important note added from the meetings tab to the second meeting!"
          )
        end

        it "allows the user to select ongoing meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            ongoing_meeting,
            "Some notes to be added",
            1
          )

          meetings_tab.expect_upcoming_counter_to_be(1)

          expect(page).to have_test_selector(
            "op-meeting-container-#{ongoing_meeting.id}",
            text: "Some notes to be added"
          )
        end

        it "allows the user to select in progress meetings (Bug #65502)" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            in_progress_meeting,
            "In progress notes",
            1
          )

          meetings_tab.expect_upcoming_counter_to_be(1)

          page.within_test_selector("op-meeting-container-#{in_progress_meeting.id}") do
            expect(page).to have_content("In progress notes")
          end
        end

        it "allows the user to select draft meetings" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            draft_meeting,
            "Draft notes",
            1
          )

          page.within_test_selector("op-meeting-container-#{draft_meeting.id}") do
            expect(page).to have_content("Draft notes")
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

            wait_for_network_idle

            raise "Expected error message to be shown" unless page.has_content?("Meeting can't be blank")
          end
        end

        it "adds presenter when the work package is added to a meeting" do
          work_package_page.visit!
          switch_to_meetings_tab

          meetings_tab.open_add_to_meeting_dialog

          meetings_tab.fill_and_submit_meeting_dialog(
            first_upcoming_meeting,
            "A very important note added from the meetings tab to the first meeting!",
            1
          )

          meeting_page.visit!

          expect(page.find(".op-meeting-agenda-item--presenter")).to have_text(user.name)
        end

        context "when testing section selection behaviour" do
          shared_let(:meeting_without_sections) { create(:meeting, project:, start_time: 1.hour.from_now) }
          shared_let(:meeting_with_sections) do
            create(:meeting, project:, start_time: 2.hours.from_now).tap do |meeting|
              create(:meeting_section, meeting:, title: "Section 1")
              create(:meeting_section, meeting:, title: "Section 2")
            end
          end
          shared_let(:recurring_meeting) do
            create(:recurring_meeting, project:)
          end
          shared_let(:empty_recurring_meeting_occurrence) do
            create(:recurring_meeting_occurrence,
                   project:,
                   recurring_meeting:,
                   start_time: 3.hours.from_now)
          end
          shared_let(:recurring_meeting_occurrence) do
            create(:recurring_meeting_occurrence,
                   project:,
                   recurring_meeting:,
                   start_time: 4.hours.from_now).tap do |meeting|
              create(:meeting_section, meeting:, title: "Section 1")
              create(:meeting_section, meeting:, title: "Section 2")
            end
          end

          it "automatically selects the backlog for one-time meetings without sections" do
            check_section_auto_selection(meeting_without_sections, "Agenda backlog")
          end

          it "automatically selects the backlog for one-time meetings with sections" do
            check_section_auto_selection(meeting_with_sections, "Agenda backlog")
          end

          it "automatically selects the last section for recurring meeting occurrences that is not the series backlog" do
            last_section = recurring_meeting_occurrence.sections.last.title
            check_section_auto_selection(recurring_meeting_occurrence, last_section)
          end

          it "always has the series backlog as a manually selectable option" do
            work_package_page.visit!
            switch_to_meetings_tab

            meetings_tab.open_add_to_meeting_dialog

            fill_in("meeting_agenda_item_meeting_id", with: recurring_meeting_occurrence.title)
            page.find(".ng-option-marked", text: recurring_meeting_occurrence.title)
            page.find(".ng-option-marked").click

            wait_for_network_idle

            section_field = find_field("meeting_agenda_item_meeting_section_id")
            section_field.click

            expect(page).to have_css(".ng-option", text: "Series backlog")
          end

          it "shows the automatically created untitled section when no sections exist for recurring meeting occurrences" do
            meeting = empty_recurring_meeting_occurrence

            check_section_auto_selection(meeting, "Untitled section")
          end

          it "updates section selection when switching between meetings" do
            work_package_page.visit!
            switch_to_meetings_tab

            meetings_tab.open_add_to_meeting_dialog

            retry_block do
              fill_in("meeting_agenda_item_meeting_id", with: recurring_meeting_occurrence.title)
              page.find(".ng-option-marked", text: recurring_meeting_occurrence.title)
              page.find(".ng-option-marked").click

              wait_for_network_idle

              last_section = recurring_meeting_occurrence.sections.last
              expect(page).to have_content(last_section.title)

              fill_in("meeting_agenda_item_meeting_id", with: meeting_without_sections.title)
              page.find(".ng-option-marked", text: meeting_without_sections.title)
              page.find(".ng-option-marked").click

              wait_for_network_idle

              expect(page).to have_content("Agenda backlog")
            end
          end

          it "shows section autocompleter as disabled when no meeting is selected" do
            work_package_page.visit!
            switch_to_meetings_tab

            meetings_tab.open_add_to_meeting_dialog

            page.find_field("meeting_agenda_item_meeting_section_id", disabled: true, visible: false)
            expect(page).to have_content("Meeting selection is required first")
          end
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

    it_behaves_like "with a meetings tab"
  end

  describe "work package split view" do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like "with a meetings tab"
  end

  private

  def switch_to_meetings_tab
    work_package_page.switch_to_tab(tab: "meetings")
    meetings_tab.expect_tab_content_rendered # wait for the tab to be rendered
  end

  def check_section_auto_selection(meeting, expected_section)
    work_package_page.visit!
    switch_to_meetings_tab

    meetings_tab.open_add_to_meeting_dialog

    fill_in("meeting_agenda_item_meeting_id", with: meeting.title)
    page.find(".ng-option-marked", text: meeting.title)
    page.find(".ng-option-marked").click

    wait_for_network_idle

    section_field = find_field("meeting_agenda_item_meeting_section_id")
    expect(section_field).not_to be_disabled

    expect(page).to have_css(".ng-value-label", text: expected_section)
  end
end
