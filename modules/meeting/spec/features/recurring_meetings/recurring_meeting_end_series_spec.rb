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

RSpec.describe "Recurring meetings end series", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings] }
  end
  shared_let(:meeting) do
    create :recurring_meeting,
           project:,
           start_time: DateTime.parse("2025-01-28T10:30:00Z"),
           duration: 1,
           frequency: "weekly",
           end_after: "never",
           author: user
  end

  let(:current_user) { user }
  let(:show_page) { Pages::RecurringMeeting::Show.new(meeting) }
  let(:meetings_page) { Pages::Meetings::Index.new(project:) }

  before do
    travel_to(Time.zone.local(2025, 1, 29, 9, 30))

    login_as current_user

    # Assuming the first init job has run
    RecurringMeetings::InitNextOccurrenceJob.perform_now(meeting, meeting.first_occurrence.to_time)
  end

  after do
    travel_back
  end

  it "can end the meeting early" do
    show_page.visit!

    show_page.end_meeting_series
    show_page.within_modal "End meeting series" do
      expect(page).to have_text("Ending the series will delete any future open or scheduled meeting occurrences")

      retry_block do
        check "I understand that this deletion cannot be reversed.", allow_label_click: true
        expect(page).to have_checked_field("I understand that this deletion cannot be reversed.")
      end

      click_on "End series now"
    end

    expect(page).to have_current_path project_recurring_meeting_path(project, meeting)
    expect(page).to have_text("Meeting series ended")
  end

  context "with invited participants" do
    let(:participant) do
      create(:user,
             member_with_permissions: { project => %i[view_meetings] })
    end

    before do
      meeting.template.participants.create!(user: participant, invited: true)
    end

    it "sends series ended emails to each participant" do
      show_page.visit!

      show_page.end_meeting_series
      show_page.within_modal "End meeting series" do
        retry_block do
          check "I understand that this deletion cannot be reversed.", allow_label_click: true
          click_on "End series now"
        end
      end

      expect(page).to have_text("Meeting series ended")

      perform_enqueued_jobs

      expect(ActionMailer::Base.deliveries.size).to eq 2
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to contain_exactly user.mail, participant.mail
      subject = ActionMailer::Base.deliveries.map(&:subject).uniq.first
      expect(subject).to include("Ended:")
      expect(subject).to include(meeting.title)
    end
  end

  context "when meeting start time is in the future" do
    before do
      meeting.update! start_time: DateTime.parse("2025-01-30T10:30:00Z")
    end

    it "does not show this action" do
      show_page.visit!
      page.find_test_selector("recurring-meeting-action-menu").click
      expect(page).to have_no_text "End meeting series"
    end
  end

  context "when meeting start time is today" do
    before do
      meeting.update! start_time: DateTime.parse("2025-01-29T20:30:00Z")
    end

    it "does not show this action" do
      show_page.visit!
      page.find_test_selector("recurring-meeting-action-menu").click
      expect(page).to have_no_text "End meeting series"
    end
  end
end
