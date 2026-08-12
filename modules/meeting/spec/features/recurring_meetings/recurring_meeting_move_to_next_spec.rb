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
require_relative "../../support/pages/recurring_meeting/show"
require_relative "../../support/pages/meetings/index"

RSpec.describe "Recurring meetings move to next meeting", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user_with_manage_permissions) do
    create :user,
           lastname: "Manager",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas] }
  end
  shared_let(:user_with_view_permissions) do
    create :user,
           lastname: "Viewer",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings] }
  end
  shared_let(:series) do
    create :recurring_meeting,
           project:,
           start_time: DateTime.parse("2025-01-28T10:30:00Z"),
           duration: 1,
           frequency: "weekly",
           end_after: "never",
           author: user_with_manage_permissions
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: DateTime.parse("2025-01-28T10:30:00Z"),
           duration: 1,
           author: user_with_manage_permissions
  end

  let!(:recurring_meeting) do
    # Assuming the first init job has run
    RecurringMeetings::InitNextOccurrenceJob.perform_now(series, series.first_occurrence.to_time)

    series.meetings.not_templated.first
  end

  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Test notes") }
  let(:meeting_page) { Pages::Meetings::Show.new(meeting) }

  before do
    login_as current_user

    meeting_page.visit!
  end

  context "when viewing a recurring meeting" do
    let(:meeting) { recurring_meeting }

    context "with manage_agendas permission" do
      let(:current_user) { user_with_manage_permissions }

      it "shows the move to next meeting option" do
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.move_item_to_next_meeting(agenda_item)

        expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")

        meeting_page.expect_no_agenda_item(title: "Test notes")
      end
    end

    context "with manage_agendas permission, but next occurrence is cancelled" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let!(:cancelled_occurrence) do
        create(:meeting,
               recurring_meeting: series,
               start_time: first_occurrence_time,
               recurrence_start_time: first_occurrence_time,
               state: :cancelled)
      end

      it "skips the cancelled occurrence and moves to the next available one" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.select_action(agenda_item, "Move to next meeting")

        expect(page).to have_text("Move to next meeting?")
        expect(page).to have_text("Note: Skipping cancelled meeting")

        page.within_modal "Move to next meeting?" do
          click_on "Move"
        end

        expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")
        meeting_page.expect_no_agenda_item(title: "Test notes")
      end
    end

    context "with manage_agendas permission, but multiple next occurrences are cancelled" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }
      let!(:first_cancelled_occurrence) do
        create(:meeting,
               recurring_meeting: series,
               start_time: first_occurrence_time,
               recurrence_start_time: first_occurrence_time,
               state: :cancelled)
      end
      let!(:second_cancelled_occurrence) do
        create(:meeting,
               recurring_meeting: series,
               start_time: second_occurrence_time,
               recurrence_start_time: second_occurrence_time,
               state: :cancelled)
      end

      it "skips all cancelled occurrences and shows the count in the dialog" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.select_action(agenda_item, "Move to next meeting")

        expect(page).to have_text("Move to next meeting?")
        expect(page).to have_text("Note: Skipping 2 cancelled meetings")

        page.within_modal "Move to next meeting?" do
          click_on "Move"
        end

        expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")
        meeting_page.expect_no_agenda_item(title: "Test notes")
      end
    end

    context "with manage_agendas permission, but next occurrence is closed" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let!(:closed_occurrence) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, first_occurrence_time)
        occurrence = series.meetings.not_templated.find_by(start_time: first_occurrence_time)
        occurrence.update!(state: :closed)
        occurrence
      end

      it "skips the closed occurrence and moves to the next available one" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.select_action(agenda_item, "Move to next meeting")

        expect(page).to have_text("Move to next meeting?")
        expect(page).to have_text("Note: Skipping closed meeting")

        page.within_modal "Move to next meeting?" do
          click_on "Move"
        end

        expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")
        meeting_page.expect_no_agenda_item(title: "Test notes")
      end
    end

    context "with manage_agendas permission, but next occurrence is cancelled and the one after is closed" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }
      let!(:cancelled_occurrence) do
        create(:recurring_meeting_occurrence,
               state: :cancelled,
               recurring_meeting: series,
               start_time: first_occurrence_time)
      end
      let!(:closed_occurrence) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, second_occurrence_time)
        occurrence = series.meetings.not_templated.find_by(start_time: second_occurrence_time)
        occurrence.update!(state: :closed)
        occurrence
      end

      it "skips both and shows both notes in the dialog" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.select_action(agenda_item, "Move to next meeting")

        expect(page).to have_text("Move to next meeting?")
        expect(page).to have_text("Note: Skipping cancelled meeting")
        expect(page).to have_text("and closed meeting")

        page.within_modal "Move to next meeting?" do
          click_on "Move"
        end

        expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")
        meeting_page.expect_no_agenda_item(title: "Test notes")
      end
    end

    context "when the occurrence has been rescheduled to an earlier time (Bug #73741)" do
      let(:current_user) { user_with_manage_permissions }
      # Feb 4 is the second Tuesday in the series (series starts Jan 28), rescheduled to Feb 3 (Monday)
      let(:scheduled_occurrence_time) { DateTime.parse("2025-02-04T10:30:00Z") }

      let!(:rescheduled_occurrence) do
        call = RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting: series)
          .call(start_time: scheduled_occurrence_time)
        occurrence_meeting = call.result

        # Reschedule to an earlier time — recurrence_start_time stays unchanged as the canonical slot
        occurrence_meeting.update!(start_time: scheduled_occurrence_time - 1.day)
        occurrence_meeting
      end

      let(:meeting) { rescheduled_occurrence }

      shared_examples "moves to a different meeting" do
        it do
          meeting_page.expect_agenda_item(title: "Test notes")

          meeting_page.select_action(agenda_item, "Move to next meeting")
          expect(page).to have_text("Move to next meeting?")

          page.within_modal "Move to next meeting?" do
            click_on "Move"
          end

          expect_and_dismiss_flash(message: "Agenda item moved to the next meeting")

          meeting_page.expect_no_agenda_item(title: "Test notes")

          next_meeting = Meeting.find(agenda_item.reload.meeting_id)
          expect(next_meeting.id).not_to eq(rescheduled_occurrence.id)

          next_meeting_page = Pages::Meetings::Show.new(next_meeting)
          next_meeting_page.visit!
          next_meeting_page.expect_agenda_item(title: "Test notes")
        end
      end

      context "when the rescheduled time is still in the future" do
        # Passing case: frozen Mon 08:00, rescheduled start_time Mon 10:30 (future), canonical slot Tue 10:30 (future)
        around { |example| travel_to(DateTime.parse("2025-02-03T08:00:00Z")) { example.run } }

        include_examples "moves to a different meeting"
      end

      context "when the rescheduled time is past but the canonical slot is in the future" do
        # Bug case: frozen Mon 12:00, rescheduled start_time Mon 10:30 (past), canonical slot Tue 10:30 (future)
        around { |example| travel_to(DateTime.parse("2025-02-03T12:00:00Z")) { example.run } }

        include_examples "moves to a different meeting"
      end
    end

    context "with view permission only" do
      let(:current_user) { user_with_view_permissions }

      it "does not show the move to next meeting option" do
        meeting_page.expect_agenda_item(title: "Test notes")

        meeting_page.open_menu(agenda_item) do
          expect(page).to have_no_css(".ActionListItem-label", text: "Move to next meeting")
          expect(page).to have_css(".ActionListItem-label", count: 1)
        end
      end
    end
  end

  context "when viewing a one-time meeting" do
    let(:current_user) { user_with_manage_permissions }

    it "does not show the move to next meeting option" do
      meeting_page.expect_agenda_item(title: "Test notes")
      meeting_page.open_menu(agenda_item) do
        expect(page).to have_text("Edit")
        expect(page).to have_no_text("Move to next meeting")
      end
    end
  end
end
