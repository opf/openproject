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

RSpec.describe "Recurring meetings creation",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings
                                                    manage_agendas] }).tap do |u|
      u.pref[:time_zone] = "Etc/UTC"

      u.save!
    end
  end
  shared_let(:other_user) do
    create(:user,
           lastname: "Second",
           member_with_permissions: { project => %i[view_meetings] })
  end
  shared_let(:third_user) do
    create(:user,
           lastname: "Third",
           member_with_permissions: { project => %i[view_meetings] })
  end
  shared_let(:no_member_user) do
    create(:user,
           lastname: "Third")
  end

  let(:current_user) { user }
  let(:meeting) { RecurringMeeting.last }
  let(:show_page) { Pages::RecurringMeeting::Show.new(meeting) }
  let(:template_page) { Pages::Meetings::Show.new(meeting.template) }
  let(:meetings_page) { Pages::Meetings::Index.new(project:) }

  before do
    travel_to(Date.new(2024, 12, 1))
  end

  after do
    travel_back
  end

  def perform_debounced_meeting_notification_jobs
    perform_enqueued_jobs(only: Meetings::NotificationDebounceJob, at: 2.minutes.from_now)
    perform_enqueued_jobs
  end

  context "with a user with permissions" do
    it "can create a recurring meeting" do
      login_as current_user
      meetings_page.visit!
      expect(page).to have_current_path(meetings_page.path)
      meetings_page.click_on "add-meeting-button"

      page.within("action-list") do
        meetings_page.click_on "Recurring"
      end

      wait_for_network_idle

      meetings_page.set_title "Some title"

      meetings_page.set_starts_on "2024-12-31"
      meetings_page.set_start_time "13:30"
      meetings_page.set_duration "1.5"
      meetings_page.set_end_after "a specific date"
      meetings_page.set_end_date "2025-01-15"

      # quick fix as wait_for_network_idle isn't working all the time
      expect(page).to have_text("Every week on Tuesday at 01:30 PM", wait: 2)

      meetings_page.click_create
      expect_and_dismiss_flash(type: :success, message: "Successful creation.")

      # User is redirected to the template
      expect(page).to have_current_path(project_meeting_path(project, meeting.template))
      expect(page).to have_content(I18n.t("recurring_meeting.template.description"))

      # Add participants
      template_page.open_participant_form
      template_page.in_participant_form do
        template_page.expect_participant(user, editable: false)
        template_page.expect_available_participants(count: 1)

        template_page.select_participant(other_user)
        template_page.expect_participant(other_user, editable: false)
        template_page.expect_available_participants(count: 2)

        page.find(".close-button").click
      end
      wait_for_network_idle

      expect(page).to have_css("#meetings-side-panel-participants-component", text: 2)

      perform_debounced_meeting_notification_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 0

      # Before exiting draft mode, user is always redirected to the template
      show_page.visit!
      expect(page).to have_current_path(project_meeting_path(project, meeting.template))

      # Series can still be deleted without opening the first meeting
      page.find_test_selector("op-meetings-header-action-trigger").click
      page.within(".Overlay") do
        expect(page).to have_css(".ActionListItem-label", text: "Delete meeting series")
      end

      expect(page).to have_css("#meetings-side-panel-state-component")

      template_page.open_first_meeting
      wait_for_network_idle

      # State component is only visible for draft mode in a template
      expect(page).to have_no_selector("#meetings-side-panel-state-component")

      # Sends out an invitation to the series
      show_page.visit!
      expect(page).to have_css(".start_time", count: 3)

      show_page.expect_open_meeting date: "12/31/2024 01:30 PM"
      show_page.expect_planned_meeting date: "01/07/2025 01:30 PM"
      show_page.expect_planned_meeting date: "01/14/2025 01:30 PM"

      perform_debounced_meeting_notification_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 2
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to contain_exactly user.mail, other_user.mail
      title = ActionMailer::Base.deliveries.map(&:subject).uniq.first
      expect(title).to eq "[#{project.name}] Meeting series 'Some title'"
      ActionMailer::Base.deliveries.clear

      # Edit the template again
      template_page.visit!

      template_page.open_participant_form
      template_page.in_participant_form do
        template_page.expect_participant(user, editable: false)
        template_page.expect_participant(other_user, editable: false)
        template_page.expect_available_participants(count: 2)

        template_page.uncheck_apply_to_upcoming
        template_page.select_participant(third_user)
        template_page.expect_participant(third_user, editable: false)
        template_page.expect_available_participants(count: 3)

        page.find(".close-button").click
      end
      wait_for_network_idle

      expect(page).to have_css("#meetings-side-panel-participants-component", text: 3)

      perform_debounced_meeting_notification_jobs
      expect(ActionMailer::Base.deliveries.size).to eq 3
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to contain_exactly user.mail, other_user.mail, third_user.mail
    end
  end

  context "as a user with viewing permissions only" do
    let(:current_user) { other_user }

    it "does not offer that option" do
      login_as current_user
      meetings_page.visit!
      expect(page).to have_current_path(meetings_page.path)
      expect(page).not_to have_test_selector("add-meeting-button")
    end
  end

  context "when the start date does not match a working-day schedule",
          with_settings: { working_days: [1, 2, 3, 4, 5] } do
    it "shows the start mismatch information in the dialog and can be cancelled" do
      login_as current_user
      meetings_page.visit!
      meetings_page.click_on "add-meeting-button"

      page.within("action-list") do
        meetings_page.click_on "Recurring"
      end

      saturday = Date.current.next_occurring(:saturday)
      expected_first_occurrence = RecurringMeeting.new(
        start_date: saturday.to_s,
        start_time_hour: "10:00",
        frequency: "working_days",
        interval: 1,
        time_zone: user.time_zone
      ).first_occurrence
      expected_occurrence_text = format_time(
        expected_first_occurrence,
        time_zone: user.time_zone
      )

      within "#new-meeting-dialog" do
        meetings_page.set_title "Start mismatch test"
        page.select(I18n.t("recurring_meeting.frequency.working_days"), from: "Frequency")
        meetings_page.set_starts_on saturday.to_s
        meetings_page.set_start_time "10:00"

        expect(page).to have_text("Every working day at 10:00 AM")
        expect(page).to have_text("The first occurrence of this series will be")
        expect(page).to have_text(expected_occurrence_text)

        page.find(".close-button").click
      end

      expect(page).to have_no_selector("#new-meeting-dialog", wait: 10)
    end
  end
end
