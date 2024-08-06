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

RSpec.describe "My spent time widget with a negative time zone", :js,
               with_settings: { start_of_week: 1 } do
  let(:beginning_of_week) { monday }
  let(:end_of_week) { sunday }
  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:tuesday) { beginning_of_week + 1.day }
  let(:thursday) { beginning_of_week + 3.days }
  let(:sunday) { beginning_of_week + 6.days }
  let(:time_zone) { "America/New_York" }

  let!(:type) { create(:type) }
  let!(:project) { create(:project, types: [type]) }
  let!(:activity) { create(:time_entry_activity, name: "Development") }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           author: user)
  end
  let!(:time_entry) do
    create(:time_entry,
           spent_on: monday,
           work_package:,
           project:,
           activity:,
           user:)
  end
  let(:user) do
    create(:user,
           preferences: { time_zone: },
           member_with_permissions: { project => %i[view_time_entries edit_time_entries view_work_packages log_own_time] })
  end
  let(:my_page) { Pages::My::Page.new }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let!(:week_days) { week_with_saturday_and_sunday_as_weekend }
  let!(:non_working_day) { create(:non_working_day, date: tuesday) }

  before do
    login_as user
    my_page.visit!
  end

  it "correctly displays non-working days and prefills day when logging time [fix #49779]",
     driver: :chrome_new_york_time_zone do
    my_page.add_widget(1, 1, :within, "My spent time")

    my_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

    expect(page)
      .to have_content time_entry.spent_on.strftime("%-m/%-d")

    aggregate_failures("non-working days are displayed properly") do
      expect(page).to have_button("Today", disabled: true)
      expect(page).to have_no_css(".fc-day-mon.fc-non-working-day")
      expect(page).to have_css(".fc-day-tue.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-wed.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-thu.fc-non-working-day")
      expect(page).to have_no_css(".fc-day-fri.fc-non-working-day")
      expect(page).to have_css(".fc-day-sat.fc-non-working-day")
      expect(page).to have_css(".fc-day-sun.fc-non-working-day")
    end

    aggregate_failures("when clicking a day, time entry day is set to the day clicked (Thursday)") do
      find(".fc-day-thu .te-calendar--add-entry", visible: false).click
      time_logging_modal.has_field_with_value "spentOn", thursday.iso8601
    end
  end
end
