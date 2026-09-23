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
require_relative "../../support/pages/my/page"

RSpec.describe "My page my spent time widget", :js, with_settings: { start_of_week: 1 } do
  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:wednesday) { monday + 2.days }
  let(:thursday) { monday + 3.days }
  let(:last_monday) { monday - 1.week }

  let!(:type) { create(:type) }
  let!(:project) { create(:project, types: [type]) }
  let!(:activity) { create(:time_entry_activity) }
  let!(:work_package) do
    create(:work_package, project:, type:, author: user, subject: "First work package")
  end

  let!(:monday_entry) do
    create(:time_entry, entity: work_package, project:, activity:, user:, spent_on: monday, hours: 3)
  end
  let!(:wednesday_entry) do
    create(:time_entry, entity: work_package, project:, activity:, user:, spent_on: wednesday, hours: 2)
  end
  let!(:last_week_entry) do
    create(:time_entry, entity: work_package, project:, activity:, user:, spent_on: last_monday, hours: 8)
  end
  let!(:other_users_entry) do
    create(:time_entry, entity: work_package, project:, activity:, user: other_user, hours: 4, spent_on: monday)
  end

  let(:other_user) { create(:user) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_time_entries edit_time_entries view_work_packages log_own_time] })
  end

  let!(:my_page_grid) { create(:my_page, :empty, user:) }
  let!(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:my_page) { Pages::My::Page.new }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }

  before do
    login_as user
    my_page.visit!

    my_page.add_widget(1, 1, :within, "My spent time")
    my_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)
  end

  it "shows the current user's entries for the week, with a total per day" do
    expect(page).to have_css(".te-stack--time-entry", count: 2)

    aggregate_failures("each entry is shown with its duration and work package") do
      expect(page).to have_css(".te-stack--card", text: "3h")
      expect(page).to have_css(".te-stack--card", text: "2h")
      expect(page).to have_css(".te-stack--card", text: work_package.subject)
    end

    aggregate_failures("the footer totals the day, leaving out the other user's entry") do
      expect(day_footer(monday)).to have_text("3h")
      expect(day_footer(wednesday)).to have_text("2h")
      expect(day_footer(thursday)).to have_text("0h")
    end
  end

  it "steps through the weeks" do
    step_to Date.current - 1.week

    expect(page).to have_css(".te-stack--card", text: "8h")
    expect(page).to have_css(".te-stack--time-entry", count: 1)

    step_to_today

    expect(page).to have_css(".te-stack--time-entry", count: 2)
  end

  it "logs time on the day that was selected" do
    select_day(thursday)

    time_logging_modal.is_visible true
    time_logging_modal.has_field_with_value "spent_on", thursday.iso8601

    time_logging_modal.update_field "entity_id", work_package.subject
    time_logging_modal.update_field "activity_id", activity.name
    time_logging_modal.submit

    time_logging_modal.is_visible false

    expect(page).to have_css(".te-stack--time-entry", count: 3)
    expect(TimeEntry.where(user:, spent_on: thursday)).to exist
  end

  it "opens an existing entry for editing" do
    first(".te-stack--time-entry").click

    time_logging_modal.is_visible true
    time_logging_modal.expect_work_package(work_package)
    time_logging_modal.has_field_with_value "spent_on", monday.iso8601
  end

  it "validates that a work package is set" do
    select_day(thursday)

    time_logging_modal.is_visible true
    time_logging_modal.submit

    time_logging_modal.is_visible true
    time_logging_modal.field_has_error "entity_id", "can't be blank."
  end

  def day_footer(date)
    column = find("th.fc-col-header-cell[data-date='#{date.iso8601}']")
    index = all("th.fc-col-header-cell").index { |cell| cell[:"data-date"] == column[:"data-date"] }

    all("th.fc-col-footer-cell")[index]
  end

  # The navigation steps the widget rather than the page, so its links carry the date they
  # lead to.
  def step_to(date)
    first("a[href*='date=#{date.iso8601}']").click
  end

  def step_to_today
    first("a[href*='date=today']").click
  end

  # The slot lanes lie over the day columns and are what a click actually lands on, so the
  # day is picked by clicking a lane at that column's horizontal centre, as a user does.
  def select_day(date)
    # The stack renders once its frame has loaded, so wait for the grid before measuring it.
    find("td.fc-timegrid-col[data-date='#{date.iso8601}']")

    offset = page.evaluate_script(<<~JS)
      (() => {
        const column = document.querySelector("td.fc-timegrid-col[data-date='#{date.iso8601}']");
        const lanes = document.querySelectorAll('td.fc-timegrid-slot-lane');
        const lane = lanes[lanes.length - 1];
        const c = column.getBoundingClientRect();
        const l = lane.getBoundingClientRect();
        return Math.round((c.left + (c.width / 2)) - (l.left + (l.width / 2)));
      })()
    JS

    all("td.fc-timegrid-slot-lane").last.click(x: offset, y: 0)
  end
end
