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

require_relative "../support/pages/meetings/show"
require_relative "../support/pages/recurring_meeting/show"

RSpec.describe "Meeting Backlogs", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas manage_outcomes] }
  end
  shared_let(:reader) do
    create :user,
           lastname: "Reader",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end

  let(:current_user) { user }
  let(:state) { :open }

  let(:show_page) { Pages::Meetings::Show.new(meeting) }
  let(:template_page) { Pages::Meetings::Show.new(recurring_meeting.template) }

  let(:first_occurrence) { recurring_meeting.meetings.where(template: false).first }
  let(:first_occurrence_page) { Pages::Meetings::Show.new(first_occurrence) }

  let(:next_occurrence) { recurring_meeting.meetings.where(template: false).last }
  let(:next_occurrence_page) { Pages::Meetings::Show.new(next_occurrence) }

  before do
    login_as current_user
  end

  describe "for one-time meetings" do
    describe "backlog visibility" do
      context "when the meeting is 'open'" do
        it "is expanded" do
          show_page.visit!
          show_page.expect_backlog collapsed: false
        end
      end

      context "when the meeting is 'in progress'" do
        before do
          meeting.update(state: :in_progress)
        end

        it "is collapsed" do
          show_page.visit!
          show_page.expect_backlog collapsed: true
        end
      end

      context "when the meeting is 'closed'" do
        before do
          meeting.update(state: :closed)
        end

        it "is not visible" do
          show_page.visit!
          show_page.expect_no_backlog
        end
      end

      context "when meeting state is changed" do
        it "collapses and expands the backlog" do
          show_page.visit!
          show_page.expect_backlog collapsed: false
          show_page.start_meeting
          show_page.expect_backlog collapsed: true
          show_page.close_meeting_from_in_progress
          show_page.expect_no_backlog
          show_page.reopen_meeting
          show_page.expect_backlog collapsed: false
        end
      end
    end

    describe "backlog actions" do
      let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
      let!(:work_package) { create(:work_package, project:) }
      let!(:wp_agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:) }

      before do
        meeting.update(state: :in_progress)
      end

      it "work correctly and keep collapsed state" do
        show_page.visit!

        # check initial state
        show_page.expect_backlog collapsed: true
        show_page.expect_backlog_count(0)

        # add first item and autoexpand backlog
        show_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Backlog agenda item"
        end
        show_page.expect_backlog_count(1)
        show_page.expect_backlog collapsed: false
        show_page.within_backlog do
          show_page.expect_agenda_item(title: "Backlog agenda item")
        end

        # add more items
        show_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Second backlog agenda item"
        end
        show_page.expect_backlog_count(2)
        show_page.expect_backlog collapsed: false
        show_page.within_backlog do
          show_page.expect_agenda_item(title: "Second backlog agenda item")
        end

        # check for correct agenda item actions outside of backlog
        agenda_item = MeetingAgendaItem.find(meeting_agenda_item.id)
        show_page.expect_non_backlog_actions(agenda_item)

        # move item to backlog
        wp_item = MeetingAgendaItem.find(wp_agenda_item.id)
        show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_backlog))

        show_page.expect_backlog_count(3)
        show_page.expect_backlog collapsed: false

        # check for correct agenda item actions within backlog
        item = MeetingAgendaItem.find_by(title: "Backlog agenda item")
        show_page.expect_backlog_actions(item)

        # reorder items within backlog
        show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_top))
        show_page.expect_backlog collapsed: false

        # move item to current meeting
        show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_current_meeting))
        show_page.expect_backlog_count(2)
        show_page.expect_backlog collapsed: false

        # edit item
        show_page.edit_agenda_item(item) do
          fill_in "Title", with: "Updated title"
        end
        show_page.expect_backlog collapsed: false

        # delete item
        show_page.remove_agenda_item(item)
        show_page.expect_backlog_count(1)
        show_page.expect_backlog collapsed: false

        # empty backlog manually
        last_item = MeetingAgendaItem.find_by(title: "Second backlog agenda item")
        show_page.remove_agenda_item(last_item)
        show_page.expect_backlog_count(0)
        show_page.expect_backlog collapsed: false
        show_page.expect_empty_backlog

        # clear and autocollapse backlog
        show_page.select_action(wp_item, I18n.t(:label_agenda_item_move_to_backlog))
        show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_backlog))
        show_page.clear_backlog
        show_page.expect_backlog collapsed: true

        # expect all agenda items to be removed (Bug #67844)
        show_page.click_on_backlog
        show_page.expect_empty_backlog
      end

      it "shows a confirmation dialog when moving items with unsaved changes" do
        # Moving item to backlog with unsaved changes for a backlog item
        show_page.visit!

        show_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Backlog item"
        end

        agenda_item = MeetingAgendaItem.find(meeting_agenda_item.id)
        backlog_item = MeetingAgendaItem.find_by(title: "Backlog item")

        show_page.edit_agenda_item(backlog_item, save: false) do
          fill_in "Title", with: "Unsaved edit"
        end
        show_page.expect_backlog_count(1)

        dismiss_confirm do
          show_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_backlog))
        end

        show_page.expect_backlog_count(1)
        show_page.expect_item_edit_form(backlog_item, visible: true)

        click_on "Cancel"

        # Moving item to current meeting with unsaved changes for a meeting item
        show_page.edit_agenda_item(agenda_item, save: false) do
          fill_in "Title", with: "Unsaved edit"
        end
        show_page.expect_backlog_count(1)

        dismiss_confirm do
          show_page.select_action(backlog_item, I18n.t(:label_agenda_item_move_to_current_meeting))
        end

        show_page.expect_backlog_count(1)
        show_page.expect_item_edit_form(agenda_item, visible: true)
      end
    end
  end

  describe "for meeting series" do
    shared_let(:recurring_meeting) do
      create :recurring_meeting,
             project:,
             start_time: "2024-12-31T13:30:00Z",
             duration: 1,
             frequency: "daily",
             end_after: "specific_date",
             end_date: "2025-01-03",
             author: user
    end

    before do
      travel_to(Date.new(2024, 12, 30))

      # Assuming the first and second occurrences are open
      first_occurrence_time = recurring_meeting.first_occurrence.to_time
      next_occurrence_time = recurring_meeting.next_occurrence(from_time: recurring_meeting.first_occurrence.to_time + 2.hours)
      RecurringMeetings::InitNextOccurrenceJob.perform_now(recurring_meeting, first_occurrence_time)
      RecurringMeetings::InitNextOccurrenceJob.perform_now(recurring_meeting, next_occurrence_time)
    end

    after do
      travel_back
    end

    describe "backlog visibility" do
      context "when the meeting is 'open'" do
        it "is expanded" do
          first_occurrence_page.visit!
          first_occurrence_page.expect_series_backlog collapsed: false
        end
      end

      context "when the meeting is 'in progress'" do
        before do
          first_occurrence.update(state: :in_progress)
        end

        it "is collapsed" do
          first_occurrence_page.visit!
          first_occurrence_page.expect_series_backlog collapsed: true
        end
      end

      context "when the meeting is 'closed'" do
        before do
          first_occurrence.update(state: :closed)
        end

        it "is not visible" do
          first_occurrence_page.visit!
          first_occurrence_page.expect_no_backlog
        end
      end

      context "when meeting state is changed" do
        it "collapses and expands the backlog" do
          next_occurrence_page.visit!
          next_occurrence_page.expect_series_backlog collapsed: false
          next_occurrence_page.start_meeting
          next_occurrence_page.expect_series_backlog collapsed: true
          next_occurrence_page.close_meeting_from_in_progress
          next_occurrence_page.expect_no_backlog
          next_occurrence_page.reopen_meeting
          next_occurrence_page.expect_series_backlog collapsed: false
        end
      end
    end

    describe "backlog actions" do
      let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting: first_occurrence) }

      before do
        first_occurrence.update(state: :in_progress)
      end

      it "work correctly and keep collapsed state" do
        first_occurrence_page.visit!

        # check initial state
        first_occurrence_page.expect_backlog_count(0)

        # add first item and autoexpand backlog
        first_occurrence_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Backlog agenda item"
        end
        first_occurrence_page.expect_backlog_count(1)
        first_occurrence_page.expect_series_backlog collapsed: false
        first_occurrence_page.within_backlog do
          first_occurrence_page.expect_agenda_item(title: "Backlog agenda item")
        end

        # add more items
        first_occurrence_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Second backlog agenda item"
        end
        first_occurrence_page.expect_backlog_count(2)
        first_occurrence_page.expect_series_backlog collapsed: false
        first_occurrence_page.within_backlog do
          first_occurrence_page.expect_agenda_item(title: "Second backlog agenda item")
        end

        # check for correct agenda item actions outside of backlog
        agenda_item = MeetingAgendaItem.find(meeting_agenda_item.id)
        first_occurrence_page.expect_non_backlog_actions(agenda_item, series: true)

        # check for correct agenda item actions within backlog
        item = MeetingAgendaItem.find_by(title: "Backlog agenda item")
        first_occurrence_page.expect_backlog_actions(item, series: true)

        # reorder items within backlog
        first_occurrence_page.select_action(item, I18n.t(:label_agenda_item_move_to_bottom))
        first_occurrence_page.expect_series_backlog collapsed: false

        # edit item
        first_occurrence_page.edit_agenda_item(item) do
          fill_in "Title", with: "Updated title"
        end
        first_occurrence_page.expect_series_backlog collapsed: false

        # delete item
        first_occurrence_page.remove_agenda_item(item)
        first_occurrence_page.expect_backlog_count(1)
        first_occurrence_page.expect_series_backlog collapsed: false

        # empty backlog manually
        last_item = MeetingAgendaItem.find_by(title: "Second backlog agenda item")
        first_occurrence_page.remove_agenda_item(last_item)
        first_occurrence_page.expect_backlog_count(0)
        first_occurrence_page.expect_series_backlog collapsed: false
        first_occurrence_page.expect_empty_backlog

        # clear and autocollapse backlog
        first_occurrence_page.select_action(agenda_item, I18n.t(:label_agenda_item_move_to_backlog))
        first_occurrence_page.clear_backlog
        first_occurrence_page.expect_series_backlog collapsed: true

        # expect all agenda items to be removed (Bug #67844)
        first_occurrence_page.click_on_backlog
        first_occurrence_page.expect_empty_backlog
      end

      it "allow items to be moved from multiple occurrences to the series backlog and vice versa" do
        # move item to backlog from meeting 1
        first_occurrence_page.visit!

        item = first_occurrence.agenda_items.first
        first_occurrence_page.edit_agenda_item(item) do
          fill_in "Title", with: "Meeting 1 item"
        end

        first_occurrence_page.select_action(item, I18n.t(:label_agenda_item_move_to_backlog))
        first_occurrence_page.expect_series_backlog collapsed: true

        first_occurrence_page.expect_backlog_count(1)

        # move item to backlog from meeting 2
        next_occurrence_page.visit!

        next_occurrence_page.expect_backlog_count(1)

        other_meeting_item = next_occurrence.agenda_items.first
        next_occurrence_page.edit_agenda_item(other_meeting_item) do
          fill_in "Title", with: "Meeting 2 item"
        end

        next_occurrence_page.select_action(other_meeting_item, I18n.t(:label_agenda_item_move_to_backlog))
        next_occurrence_page.expect_series_backlog collapsed: false

        # expect both items in backlog in meeting 2
        next_occurrence_page.expect_backlog_count(2)

        # expect both items in backlog in meeting 1
        first_occurrence_page.visit!
        first_occurrence_page.expect_backlog_count(2)

        # move item from meeting 2 to meeting 1 via the backlog
        first_occurrence_page.click_on_backlog
        first_occurrence_page.select_action(other_meeting_item, I18n.t(:label_agenda_item_move_to_current_meeting))
        first_occurrence_page.expect_backlog_count(1)
        first_occurrence_page.expect_series_backlog collapsed: false
        first_occurrence_page.within_backlog do
          first_occurrence_page.expect_agenda_item(title: "Meeting 1 item")
        end

        # update moved item to check if component is updated correctly
        first_occurrence_page.edit_agenda_item(other_meeting_item) do
          fill_in "Title", with: "Meeting 2 item, now updated"
        end
        first_occurrence_page.expect_agenda_item(title: "Meeting 2 item, now updated")

        # move item from meeting 1 to meeting 2 via the backlog
        next_occurrence_page.visit!
        next_occurrence_page.expect_backlog_count(1)
        next_occurrence_page.select_action(item, I18n.t(:label_agenda_item_move_to_current_meeting))
        next_occurrence_page.expect_empty_backlog

        # delete moved item to check if component is updated properly
        next_occurrence_page.remove_agenda_item(item)
      end

      it "do not change the new button component to the one from the template (Bug #64106)" do
        next_occurrence_page.visit!

        template_item = next_occurrence.agenda_items.first
        next_occurrence_page.remove_agenda_item(template_item)

        next_occurrence_page.add_agenda_item_to_backlog do
          fill_in "Title", with: "Backlog agenda item"
        end
        next_occurrence_page.expect_backlog_count(1)
        next_occurrence_page.within_backlog do
          next_occurrence_page.expect_agenda_item(title: "Backlog agenda item")
        end

        next_occurrence_page.check_add_section_path(next_occurrence)

        item = MeetingAgendaItem.find_by(title: "Backlog agenda item")
        next_occurrence_page.select_action(item, I18n.t(:label_agenda_item_move_to_current_meeting))
        next_occurrence_page.expect_empty_backlog

        next_occurrence_page.check_add_section_path(next_occurrence)
      end
    end
  end

  describe "blankslate" do
    before do
      meeting.update(state: :in_progress)
    end

    it "shows when the backlog is empty" do
      show_page.visit!
      show_page.expect_backlog collapsed: true
      show_page.expect_backlog_count(0)
      show_page.expect_blankslate
    end

    it "shows when the backlog has agenda items" do
      show_page.visit!
      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Backlog agenda item"
      end
      show_page.within_backlog do
        show_page.expect_agenda_item(title: "Backlog agenda item")
      end
      show_page.expect_blankslate
    end
  end

  describe "outcomes" do
    let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
    let(:field) do
      TextEditorField.new(page, "New outcome", selector: test_selector("meeting-outcome-input-for-#{meeting_agenda_item.id}"))
    end

    before do
      meeting.update(state: :in_progress)
    end

    it "cannot be added for items in backlogs" do
      show_page.visit!
      show_page.click_on_backlog
      item = MeetingAgendaItem.find(meeting_agenda_item.id)
      show_page.select_action(item, I18n.t(:label_agenda_item_move_to_backlog))
      retry_block do
        show_page.expect_no_outcome_action(item)
      end
    end

    it "show for items that had outcomes before being moved to the backlog" do
      show_page.visit!
      show_page.click_on_backlog
      item = MeetingAgendaItem.find(meeting_agenda_item.id)
      show_page.add_outcome(item) do
        field.expect_active!
        field.set_value "Backlog outcome"
        click_link_or_button "Save"
      end
      show_page.expect_outcome "Backlog outcome"
      show_page.select_action(item, I18n.t(:label_agenda_item_move_to_backlog))
      retry_block do
        show_page.expect_no_outcome_actions
        show_page.expect_no_outcome_button
        show_page.expect_no_outcome_action(item)
      end
    end
  end

  describe "a user without permissions" do
    before do
      login_as reader
    end

    it "cannot see the backlog header actions" do
      show_page.visit!

      show_page.expect_no_backlog_header_actions
    end
  end
end
