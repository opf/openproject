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
require_relative "../support/pages/meetings/index"
require_relative "../support/pages/recurring_meeting/show"

RSpec.describe "Meeting scroll position",
               :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  describe "is restored after clicking 'Reload' in the flash banner" do
    let(:meeting) { create(:meeting, project:, author: user) }
    let(:show_page) { Pages::Meetings::Show.new(meeting) }

    before do
      25.times { create(:meeting_agenda_item, meeting:, author: user) }

      # Disable automatic polling so we can trigger it manually
      allow_any_instance_of(Meetings::HeaderComponent) # rubocop:disable RSpec/AnyInstance
        .to receive(:check_for_updates_interval)
              .and_return(0)
    end

    it do
      flash_component = ".op-primer-flash--item"

      show_page.visit!
      first_window = current_window
      second_window = open_new_window

      scroll_position = within_window(first_window) do
        expect(page).to have_test_selector("meeting-page-header")
        last_item = all("[data-test-selector='op-meeting-agenda-title']").last
        page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' });", last_item)
        page.evaluate_script("document.getElementById('content-body').scrollTop")
      end

      within_window(second_window) do
        show_page.visit!

        retry_block do
          show_page.add_agenda_item do
            fill_in "Title", with: "New item triggering update"
          end
        end
      end

      within_window(first_window) do
        show_page.trigger_change_poll
        expect(page).to have_css(flash_component)
        expect(page).to have_text(I18n.t(:notice_meeting_updated))

        click_on I18n.t("label_meeting_reload")

        expect(page).to have_test_selector("meeting-page-header")

        retry_block do
          restored_position = page.evaluate_script("document.getElementById('content-body').scrollTop")
          expect(restored_position).to be_within(25).of(scroll_position)
        end
      end
    end
  end

  describe "is restored after clicking 'Show more' in the meetings index page footer" do
    let(:index_page) { Pages::Meetings::Index.new(project:) }

    # Freeze time at 8 AM so "today" meetings scheduled for 10 AM are always in the future
    around do |example|
      freeze_time_at = Time.zone.today.beginning_of_day + 8.hours
      travel_to(freeze_time_at) { example.run }
    end

    before do
      30.times { create(:meeting, :author_participates, project:, author: user, start_time: Time.zone.today + 10.hours) }
      8.times { create(:meeting, :author_participates, project:, author: user, start_time: 2.weeks.from_now) }
    end

    it do
      index_page.visit!
      expect(page).to have_text(I18n.t(:label_recurring_meeting_show_more))

      trigger_button = find("[data-keep-scroll-position-target='triggerButton']")
      page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' });", trigger_button)
      scroll_position = page.evaluate_script("document.getElementById('content-body').scrollTop")

      trigger_button.click

      expect(page).to have_no_text(I18n.t(:label_recurring_meeting_show_more))

      retry_block do
        restored_position = page.evaluate_script("document.getElementById('content-body').scrollTop")
        expect(restored_position).to be_within(25).of(scroll_position)
      end
    end
  end

  describe "is restored after clicking 'Show more' in the recurring meeting show page footer" do
    let(:recurring_meeting) do
      create(:recurring_meeting,
             project:,
             author: user,
             start_time: Date.tomorrow + 10.hours,
             frequency: "daily",
             end_after: "iterations",
             iterations: 31)
    end
    let(:show_page) { Pages::RecurringMeeting::Show.new(recurring_meeting) }

    before do
      25.times do |i|
        meeting = create(:recurring_meeting_occurrence,
                         project:,
                         author: user,
                         recurring_meeting:,
                         start_time: (i + 4).weeks.from_now + 10.hours)
      end
    end

    it do
      show_page.visit!
      expect(page).to have_text(I18n.t(:label_recurring_meeting_show_more))

      trigger_button = find("[data-keep-scroll-position-target='triggerButton']")
      page.execute_script("arguments[0].scrollIntoView({ block: 'center', behavior: 'instant' });", trigger_button)
      scroll_position = page.evaluate_script("document.getElementById('content-body').scrollTop")

      trigger_button.click

      expect(page).to have_no_text(I18n.t(:label_recurring_meeting_show_more))

      retry_block do
        restored_position = page.evaluate_script("document.getElementById('content-body').scrollTop")
        expect(restored_position).to be_within(25).of(scroll_position)
      end
    end
  end
end
