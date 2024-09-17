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
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_calendar manage_calendars] })
  end
  let!(:current_work_package) do
    create(:work_package,
           subject: "Current work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month + 15.days,
           due_date: Time.zone.today.at_beginning_of_month + 15.days)
  end
  let!(:another_current_work_package) do
    create(:work_package,
           subject: "Another current work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month + 12.days,
           due_date: Time.zone.today.at_beginning_of_month + 18.days)
  end
  let!(:future_work_package) do
    create(:work_package,
           subject: "Future work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month.next_month + 15.days,
           due_date: Time.zone.today.at_beginning_of_month.next_month + 15.days)
  end
  let!(:another_future_work_package) do
    create(:work_package,
           subject: "Another future work package",
           project:,
           start_date: Time.zone.today.at_beginning_of_month.next_month + 12.days,
           due_date: Time.zone.today.at_beginning_of_month.next_month + 18.days)
  end
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:current_wp_split_screen) { Pages::SplitWorkPackage.new(current_work_package, project) }

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
    find(".toolbar-item a", text: "Calendar").click

    loading_indicator_saveguard

    # should open the calendar with the current month displayed
    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_future_work_package.subject

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

    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject
    expect(page)
      .to have_css ".fc-event-title", text: another_current_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: future_work_package.subject
    expect(page)
      .to have_no_css ".fc-event-title", text: another_future_work_package.subject

    # click goes to work package split screen
    page.find(".fc-event-title", text: current_work_package.subject).click
    current_wp_split_screen.expect_open

    # Going back in browser history will lead us back to the calendar
    # Regression #29664
    page.go_back
    expect(page)
      .to have_css(".fc-event-title", text: current_work_package.subject, wait: 20)
    current_wp_split_screen.expect_closed

    # click goes to work package split screen page again
    page.find(".fc-event-title", text: current_work_package.subject).click
    current_wp_split_screen.expect_open

    # click back goes back to calendar
    current_wp_split_screen.close

    expect(page)
      .to have_css ".fc-event-title", text: current_work_package.subject, wait: 20
    current_wp_split_screen.expect_closed
  end
end
