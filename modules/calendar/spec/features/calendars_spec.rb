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

RSpec.describe "Work package calendars", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_calendar manage_calendars] })
  end
  shared_let(:current_work_package) do
    create(:work_package,
           subject: "Current work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month + 15.days,
           due_date: Time.zone.today.at_beginning_of_month + 15.days)
  end
  shared_let(:another_current_work_package) do
    create(:work_package,
           subject: "Another current work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month + 12.days,
           due_date: Time.zone.today.at_beginning_of_month + 18.days)
  end
  shared_let(:future_work_package) do
    create(:work_package,
           subject: "Future work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month.next_month + 15.days,
           due_date: Time.zone.today.at_beginning_of_month.next_month + 15.days)
  end
  shared_let(:another_future_work_package) do
    create(:work_package,
           subject: "Another future work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month.next_month + 12.days,
           due_date: Time.zone.today.at_beginning_of_month.next_month + 18.days)
  end
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:current_wp_split_screen) { Pages::PrimerizedSplitWorkPackage.new(current_work_package, project) }

  before do
    login_as(user)
  end

  it "navigates to today, allows filtering, switching the view and retrains the state" do
    visit project_path(project)

    within "#main-menu" do
      click_link "Calendars"
    end

    # Expect empty index
    expect(page).to have_text "There is currently nothing to display."

    # Open a new calendar from there
    find('[data-test-selector="add-calendar-button"]', text: "Calendar").click

    loading_indicator_saveguard
    expect_angular_frontend_initialized

    # should open the calendar with the current month displayed
    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject, wait: 20
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_future_work_package.subject

    # The columns are set correctly according to month view.
    expect(page).to have_css ".fc-day-mon .fc-col-header-cell-cushion", text: "Mon"
    expect(page).to have_css ".fc-day-tue .fc-col-header-cell-cushion", text: "Tue"

    filters.expect_filter_count 1

    filters.open
    # The filter for the time frame added implicitly should not be visible
    filters.expect_no_filter_by("Dates interval", "datesInterval")

    # The user can filter by e.g. the subject filter
    filters.add_filter_by "Subject", "contains", ["Another"]

    # non matching work packages are no longer displayed
    expect(page)
      .to have_no_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject

    # The filter for the time frame added implicitly should not be visible
    filters.expect_filter_count 2

    # navigate to the next month
    find(".fc-next-button").click

    expect(page)
      .to have_no_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_future_work_package.subject

    # removing the filter will show the event again
    filters.remove_filter "subject"

    expect(page)
      .to have_no_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_future_work_package.subject

    future_url = current_url

    # navigate back a month
    find(".fc-prev-button").click

    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_future_work_package.subject

    # open the page via the url should show the next month again
    visit future_url

    expect(page).to have_test_selector("op-breadcrumbs--item", text: "Calendars")
    expect(page).to have_css(".op-breadcrumbs--current", text: "Unnamed calendar", aria: { current: "page" })

    expect(page)
      .to have_no_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_future_work_package.subject

    # go back a month by using the browser back functionality
    page.execute_script("window.history.back()")

    expect_angular_frontend_initialized
    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject, wait: 20
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_future_work_package.subject

    # click goes to work package split screen
    page.find(".fc-event-title", text: current_work_package.subject).click

    wait_for_turbo_frame do
      expect(page).to have_current_path("/projects/#{project.identifier}/calendars/new/details/#{current_work_package.id}", ignore_query: true)
      current_wp_split_screen.expect_open
    end

    # Going back in browser history will lead us back to the calendar
    # Regression #29664
    retry_block do
      page.go_back
      expect_angular_frontend_initialized
      expect(page)
        .to have_css(".fc-event-title", text: current_work_package.subject, wait: 20)
      current_wp_split_screen.expect_closed
    end

    # After go_back, the app may not be fully initialized even though the
    # calendar events are visible. Clicking too early can cause an "not
    # authorized" error on the split screen API call. Retry to handle this.
    retry_block do
      page.find(".fc-event-title", text: current_work_package.subject).click
      wait_for_turbo_frame do
        current_wp_split_screen.expect_open
      end
    end

    # click back goes back to calendar
    current_wp_split_screen.close

    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject, wait: 20
    current_wp_split_screen.expect_closed
  end

  context "when work packages have only one date set (start or due date)" do
    shared_let(:wp_start_date_only) do
      create(:work_package,
             subject: "Start date only",
             project:,
             start_date: Time.zone.today.at_beginning_of_month + 8.days)
    end
    shared_let(:wp_due_date_only) do
      create(:work_package,
             subject: "Due date only",
             project:,
             due_date: Time.zone.today.at_beginning_of_month + 8.days)
    end
    shared_let(:wp_no_dates) do
      create(:work_package,
             subject: "No dates at all",
             project:)
    end

    it "shows the event on the calendar" do
      visit project_path(project)

      within "#main-menu" do
        click_link "Calendars"
      end

      # Expect empty index
      expect(page).to have_text "There is currently nothing to display."

      # Open a new calendar from there
      find('[data-test-selector="add-calendar-button"]', text: "Calendar").click

      loading_indicator_saveguard

      expect(page)
        .to have_css ".fc-event-title", text: wp_start_date_only.subject
      expect(page)
        .to have_css ".fc-event-title", text: wp_due_date_only.subject
      expect(page)
        .to have_no_css ".fc-event-title", text: wp_no_dates.subject
    end
  end
end
