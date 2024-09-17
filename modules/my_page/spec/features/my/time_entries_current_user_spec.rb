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

RSpec.describe "My page time entries current user widget spec", :js do
  let!(:type) { create(:type) }
  let!(:project) { create(:project, types: [type]) }
  let!(:activity) { create(:time_entry_activity) }
  let!(:other_activity) { create(:time_entry_activity) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           author: user,
           subject: "First work package")
  end
  let!(:other_work_package) do
    create(:work_package,
           project:,
           type:,
           author: user,
           subject: "Another task")
  end
  let!(:visible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           activity:,
           user:,
           spent_on: Date.current.beginning_of_week(:sunday) + 1.day,
           hours: 3,
           comments: "My comment")
  end
  let!(:visible_time_entry_on_project) do
    create(:time_entry,
           work_package: nil,
           project:,
           activity:,
           user:,
           spent_on: Date.current.beginning_of_week(:sunday) + 1.day,
           hours: 1,
           comments: "My comment")
  end
  let!(:other_visible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           activity:,
           user:,
           spent_on: Date.current.beginning_of_week(:sunday) + 4.days,
           hours: 2,
           comments: "My other comment")
  end
  let!(:last_week_visible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           activity:,
           user:,
           spent_on: Date.current - (Date.current.wday + 3).days,
           hours: 8,
           comments: "My last week comment")
  end
  let!(:invisible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           activity:,
           user: other_user,
           hours: 4)
  end
  let!(:custom_field) do
    create(:time_entry_custom_field)
  end
  let(:other_user) do
    create(:user)
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_time_entries edit_time_entries view_work_packages log_own_time] })
  end
  let(:my_page) do
    Pages::My::Page.new
  end
  let(:cf_field) { TextEditorField.new(page, custom_field.attribute_name(:camel_case)) }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let!(:week_days) { week_with_saturday_and_sunday_as_weekend }

  before do
    login_as user

    my_page.visit!
  end

  it "adds the widget which then displays time entries and allows manipulating them" do
    # within top-right area, add an additional widget
    my_page.add_widget(1, 1, :within, "My spent time")

    entries_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

    my_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

    entries_area.expect_to_span(1, 1, 2, 2)

    expect(page).to have_no_css(".fc-day-mon.fc-non-working-day")
    expect(page).to have_no_css(".fc-day-tue.fc-non-working-day")
    expect(page).to have_no_css(".fc-day-wed.fc-non-working-day")
    expect(page).to have_no_css(".fc-day-thu.fc-non-working-day")
    expect(page).to have_no_css(".fc-day-fri.fc-non-working-day")
    expect(page).to have_css(".fc-day-sat.fc-non-working-day")
    expect(page).to have_css(".fc-day-sun.fc-non-working-day")

    expect(page)
      .to have_content "Total: 6 h"

    expect(page)
      .to have_content visible_time_entry.spent_on.strftime("%-m/%-d")
    expect(page)
      .to have_css(".fc-event .fc-event-title", text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    expect(page)
      .to have_content(other_visible_time_entry.spent_on.strftime("%-m/%-d"))
    expect(page)
      .to have_css(".fc-event .fc-event-title", text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    # go to last week
    within entries_area.area do
      find(".fc-toolbar .fc-prev-button").click
    end

    expect(page)
      .to have_content "Total: 8 h"

    expect(page)
      .to have_content(last_week_visible_time_entry.spent_on.strftime("%-m/%-d"))
    expect(page)
      .to have_css(".fc-event .fc-event-title", text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")

    # go to today again
    within entries_area.area do
      find(".fc-toolbar .fc-today-button").click
    end

    expect(page)
      .to have_content "Total: 6 h"

    within entries_area.area do
      find(".te-calendar--time-entry", match: :first).hover
    end

    expect(page)
      .to have_css(".ui-tooltip", text: "Project: #{project.name}")

    # Adding a time entry

    # The add time entry event is invisible
    within entries_area.area do
      find("td.fc-timegrid-col:nth-of-type(5) .te-calendar--add-entry", visible: false).click
    end

    time_logging_modal.is_visible true

    time_logging_modal.work_package_is_missing true

    time_logging_modal.has_field_with_value "spentOn", (Date.current.beginning_of_week(:sunday) + 3.days).strftime

    time_logging_modal.shows_field "user", false

    expect(page)
      .to have_no_css(".ng-spinner-loader")

    # Expect filtering works
    time_logging_modal.work_package_field.autocomplete work_package.subject, select: false

    expect(page).to have_test_selector("op-autocompleter-item-subject", text: work_package.subject)
    expect(page).not_to have_test_selector("op-autocompleter-item-subject", text: other_work_package.subject)

    time_logging_modal.update_work_package_field other_work_package.subject

    time_logging_modal.work_package_is_missing false

    time_logging_modal.update_field "comment", "Comment for new entry"

    time_logging_modal.update_field "activity", activity.name

    time_logging_modal.update_field "hours", 4

    sleep(0.1)

    time_logging_modal.perform_action "Save"
    time_logging_modal.is_visible false

    my_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_create)

    within entries_area.area do
      expect(page)
        .to have_css("td.fc-timegrid-col:nth-of-type(5) .te-calendar--time-entry",
                     text: other_work_package.subject)
    end

    expect(page)
      .to have_content "Total: 10 h"

    expect(TimeEntry.count)
      .to be 6

    ## Editing an entry

    within entries_area.area do
      all("td.fc-timegrid-col:nth-of-type(3) .te-calendar--time-entry").first.click
    end

    time_logging_modal.is_visible true

    time_logging_modal.update_field "activity", other_activity.name

    # As the other_work_package now has time logged, it is now considered to be a
    # recent work package.
    time_logging_modal.update_work_package_field other_work_package.subject, true

    time_logging_modal.update_field "hours", 6

    time_logging_modal.update_field "comment", "Some comment"

    cf_field.set_value("Cf text value")

    time_logging_modal.perform_action "Save"
    time_logging_modal.is_visible false

    sleep(0.1)
    my_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

    within entries_area.area do
      all("td.fc-timegrid-col:nth-of-type(3) .te-calendar--time-entry").first.hover
    end

    expect(page)
      .to have_css(".ui-tooltip", text: "Work package: ##{other_work_package.id}: #{other_work_package.subject}")

    expect(page)
      .to have_css(".ui-tooltip", text: "Hours: 6 h")

    expect(page)
      .to have_css(".ui-tooltip", text: "Activity: #{other_activity.name}")

    expect(page)
      .to have_css(".ui-tooltip", text: "Comment: Some comment")

    expect(page)
      .to have_content "Total: 13 h"

    ## Opening the configuration modal multiple times (Regression#54966)
    entries_area.click_menu_item I18n.t("js.grid.configure")
    click_on "Cancel"
    entries_area.click_menu_item I18n.t("js.grid.configure")

    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].each do |day_name|
      expect(page).to have_field(day_name, checked: true)
    end
    click_on "Cancel"

    ## Hiding weekdays
    entries_area.click_menu_item I18n.t("js.grid.configure")

    uncheck "Monday" # the day visible_time_entry is logged for

    click_button "Apply"

    within entries_area.area do
      expect(page)
        .to have_no_css(".fc-day-header", text: "Mon")
      expect(page)
        .to have_no_css(".fc-duration", text: "6 h")
    end

    ## Removing the time entry

    within entries_area.area do
      # to place the tooltip at a different spot
      find("td.fc-timegrid-col:nth-of-type(5) .te-calendar--time-entry").hover
      find("td.fc-timegrid-col:nth-of-type(5) .te-calendar--time-entry").click
    end

    time_logging_modal.is_visible true
    time_logging_modal.perform_action "Delete"

    page.driver.browser.switch_to.alert.accept
    time_logging_modal.is_visible false

    within entries_area.area do
      expect(page)
        .to have_no_css("td.fc-timegrid-col:nth-of-type(5) .te-calendar--time-entry")
    end

    expect(TimeEntry.where(id: other_visible_time_entry.id))
      .not_to be_exist

    ## Reloading keeps the configuration
    visit root_path
    my_page.visit!

    within entries_area.area do
      expect(page)
        .to have_content(/#{Regexp.escape(I18n.t('js.grid.widgets.time_entries_current_user.title'))}/i)

      expect(page)
        .to have_css(".te-calendar--time-entry", count: 1)

      expect(page)
        .to have_no_css(".fc-col-header-cell", text: "Mon")
    end

    # Removing the widget

    entries_area.remove

    # as the last widget has been removed, the add button is always displayed
    nucleus_area = Components::Grids::GridArea.of(2, 2)
    nucleus_area.expect_to_exist

    within nucleus_area.area do
      expect(page)
        .to have_css(".grid--widget-add")
    end
  end
end
