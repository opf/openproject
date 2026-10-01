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

RSpec.describe "Recurring meetings duplicate in next meeting", :js do
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

  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, title: "Test agenda item") }
  let(:meeting_page) { Pages::Meetings::Show.new(meeting) }

  before do
    login_as current_user

    meeting_page.visit!
  end

  context "when viewing a recurring meeting" do
    let(:meeting) { recurring_meeting }

    context "with manage_agendas permission" do
      let(:current_user) { user_with_manage_permissions }

      let!(:next_meeting) do
        # Initialize the next occurrence
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, series.next_occurrence)
        series.meetings.not_templated.last
      end

      let(:next_meeting_page) { Pages::Meetings::Show.new(next_meeting) }

      it "shows the 'duplicate in next meeting' option and duplicates the item" do
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.duplicate_item_in_next_meeting(agenda_item)

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        meeting_page.expect_agenda_item(title: "Test agenda item")

        next_meeting_page.visit!
        next_meeting_page.expect_agenda_item(title: "Test agenda item")
      end

      it "does not copy outcomes when duplicating the item" do
        create(:meeting_outcome, meeting_agenda_item: agenda_item, notes: "Original outcome")

        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.duplicate_item_in_next_meeting(agenda_item)

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        expect(agenda_item.outcomes.first.notes).to eq("Original outcome")

        next_meeting_page.visit!
        next_meeting_page.expect_agenda_item(title: "Test agenda item")

        duplicated_item = next_meeting.agenda_items.find_by(title: "Test agenda item")
        expect(duplicated_item.outcomes).to be_empty
      end
    end

    context "with manage_agendas permission, but next occurrence is cancelled" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }

      let!(:target_meeting) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, second_occurrence_time)
        series.meetings.not_templated.find_by(start_time: second_occurrence_time)
      end

      let!(:cancelled_occurrence) do
        create(:recurring_meeting_occurrence,
               recurring_meeting: series,
               state: :cancelled,
               start_time: first_occurrence_time)
      end

      let(:target_meeting_page) { Pages::Meetings::Show.new(target_meeting) }

      it "skips the cancelled occurrence and duplicates to the next available one" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.open_menu(agenda_item) do
          click_on "Duplicate"
          click_on "Duplicate in next meeting"
        end

        expect(page).to have_text("Duplicate in next meeting?")
        expect(page).to have_text("Note: Skipping cancelled meeting")

        page.within_modal "Duplicate in next meeting?" do
          click_on "Duplicate"
        end

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        target_meeting_page.visit!
        target_meeting_page.expect_agenda_item(title: "Test agenda item")
      end
    end

    context "with manage_agendas permission, but multiple next occurrences are cancelled" do
      def cancel_or_create_occurrence(at:)
        series.meetings.not_templated.find_or_initialize_by(recurrence_start_time: at).tap do |instance|
          instance.start_time = at
          instance.state = :cancelled
          instance.project ||= series.project
          instance.author ||= series.author
          instance.title ||= series.template.title
          instance.duration ||= series.template.duration
          instance.save!
        end
      end

      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }
      let(:third_occurrence_time) { series.next_occurrence(from_time: second_occurrence_time) }

      let!(:target_meeting) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, third_occurrence_time)
        series.meetings.not_templated.find_by(start_time: third_occurrence_time)
      end

      let!(:first_cancelled_occurrence) do
        cancel_or_create_occurrence(at: first_occurrence_time)
      end
      let!(:second_cancelled_occurrence) do
        cancel_or_create_occurrence(at: second_occurrence_time)
      end

      let(:target_meeting_page) { Pages::Meetings::Show.new(target_meeting) }

      it "skips all cancelled occurrences and shows the count in the dialog" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.open_menu(agenda_item) do
          click_on "Duplicate"
          click_on "Duplicate in next meeting"
        end

        expect(page).to have_text("Duplicate in next meeting?")
        expect(page).to have_text("Note: Skipping 2 cancelled meetings")

        page.within_modal "Duplicate in next meeting?" do
          click_on "Duplicate"
        end

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        target_meeting_page.visit!
        target_meeting_page.expect_agenda_item(title: "Test agenda item")
      end
    end

    context "with manage_agendas permission, but next occurrence is closed" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }

      let!(:target_meeting) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, second_occurrence_time)
        series.meetings.not_templated.find_by(start_time: second_occurrence_time)
      end

      let!(:closed_occurrence) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, first_occurrence_time)
        occurrence = series.meetings.not_templated.find_by(start_time: first_occurrence_time)
        occurrence.update!(state: :closed)
        occurrence
      end

      let(:target_meeting_page) { Pages::Meetings::Show.new(target_meeting) }

      it "skips the closed occurrence and duplicates to the next available one" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.open_menu(agenda_item) do
          click_on "Duplicate"
          click_on "Duplicate in next meeting"
        end

        expect(page).to have_text("Duplicate in next meeting?")
        expect(page).to have_text("Note: Skipping closed meeting")

        page.within_modal "Duplicate in next meeting?" do
          click_on "Duplicate"
        end

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        target_meeting_page.visit!
        target_meeting_page.expect_agenda_item(title: "Test agenda item")
      end
    end

    context "with manage_agendas permission, but next occurrence is cancelled and the one after is closed" do
      let(:current_user) { user_with_manage_permissions }
      let(:first_occurrence_time) { series.next_occurrence(from_time: Time.current) }
      let(:second_occurrence_time) { series.next_occurrence(from_time: first_occurrence_time) }
      let(:third_occurrence_time) { series.next_occurrence(from_time: second_occurrence_time) }

      let!(:target_meeting) do
        RecurringMeetings::InitNextOccurrenceJob.perform_now(series, third_occurrence_time)
        series.meetings.not_templated.find_by(start_time: third_occurrence_time)
      end

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

      let(:target_meeting_page) { Pages::Meetings::Show.new(target_meeting) }

      it "skips both and shows both notes in the dialog" do
        meeting_page.visit!
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.open_menu(agenda_item) do
          click_on "Duplicate"
          click_on "Duplicate in next meeting"
        end

        expect(page).to have_text("Duplicate in next meeting?")
        expect(page).to have_text("Note: Skipping cancelled meeting")
        expect(page).to have_text("and closed meeting")

        page.within_modal "Duplicate in next meeting?" do
          click_on "Duplicate"
        end

        expect_and_dismiss_flash(message: "Agenda item duplicated in the next meeting")

        target_meeting_page.visit!
        target_meeting_page.expect_agenda_item(title: "Test agenda item")
      end
    end

    context "with view permission only" do
      let(:current_user) { user_with_view_permissions }

      it "does not show the 'duplicate in next meeting' option" do
        meeting_page.expect_agenda_item(title: "Test agenda item")

        meeting_page.open_menu(agenda_item) do
          expect(page).to have_no_css(".ActionListItem-label", text: "Duplicate in next meeting")
        end
      end
    end
  end

  context "when viewing a one-time meeting" do
    let(:current_user) { user_with_manage_permissions }

    it "does not show the duplicate in next meeting option" do
      meeting_page.expect_agenda_item(title: "Test agenda item")
      meeting_page.open_menu(agenda_item) do
        expect(page).to have_text("Edit")
        expect(page).to have_no_text("Duplicate in next meeting")
      end
    end
  end
end
