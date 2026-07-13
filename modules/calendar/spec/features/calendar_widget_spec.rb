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
require_relative "../../../overviews/spec/support/pages/dashboard"
require_relative "../support/pages/calendar"

RSpec.describe "Calendar Widget", :js, with_settings: { start_of_week: 1 } do
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking calendar_view meetings])
  end
  shared_let(:work_package) do
    create(:work_package,
           project:,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end
  shared_let(:meeting) do
    create(:meeting, title: "Weekly", project:, start_time: Time.zone.today.beginning_of_week.next_occurring(:tuesday) + 10.hours)
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end
  let(:wp_full_view) { Pages::FullWorkPackage.new(work_package, project) }
  let(:calendar) { Pages::Calendar.new project }

  shared_let(:current_user) do
    create(:user,
           member_with_permissions: {
             project => %w[view_work_packages view_meetings edit_work_packages view_calendar manage_dashboards]
           })
  end

  before do
    login_as(current_user)
    dashboard_page.visit!

    wait_for_network_idle if using_cuprite?

    # within top-left area, add an additional widget
    dashboard_page.add_widget(1, 1, :row, "Calendar")

    dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")
  end

  it "shows the meeting" do
    expect(page).to have_css(".fc-event", text: "Weekly", visible: :all)

    page.find(".fc-event", text: "Weekly", visible: :all).click

    expect(page).to have_current_path /meetings\/#{meeting.id}/
  end

  context "as a user in a different timezone" do
    shared_let(:current_user) do
      create(:user,
             preferences: { time_zone: "Asia/Tokyo" },
             member_with_permissions: {
               project => %w[view_work_packages view_meetings edit_work_packages view_calendar manage_dashboards]
             })
    end

    it "shows the meeting in the correct timezone" do
      expect(page).to have_css(".fc-event", text: "Weekly", visible: :all)

      start_time = Time.use_zone(current_user.time_zone) { meeting.start_time.strftime("%-l:%M%P") }
      end_time = Time.use_zone(current_user.time_zone) { (meeting.start_time + 1.hour).strftime("%-l:%M%P") }
      expect(page).to have_css(".fc-event-time", text: "#{start_time} - #{end_time}", visible: :all, exact_text: false)

      page.find(".fc-event", text: "Weekly", visible: :all).click
      expect(page).to have_current_path /meetings\/#{meeting.id}/
    end
  end

  it "can resize the same work package twice (Regression #48333)", :selenium do
    expect(page).to have_css(".fc-event-title", text: work_package.subject)

    calendar.resize_date(work_package, work_package.due_date - 1.day)
    dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload
    expect(work_package.due_date).to eq Time.zone.today.beginning_of_week.next_occurring(:wednesday)

    calendar.resize_date(work_package, work_package.due_date - 1.day)
    dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload
    expect(work_package.due_date).to eq Time.zone.today.beginning_of_week.next_occurring(:tuesday)
  end

  context "when looking at the date headers" do
    let(:next_tuesday) { Time.zone.today.beginning_of_week.next_occurring(:tuesday) }
    let(:tue_css_selector) { ".fc-day-tue .fc-col-header-cell-cushion" }

    it "shows the default date format" do
      expected = /Tue #{next_tuesday.month}\/#{next_tuesday.day}/
      expect(page).to have_css(tue_css_selector, text: expected)
    end

    context "with a date format configured", with_settings: { date_format: "%d.%m.%Y" } do
      it "shows the configured date format" do
        expected = /Tue #{next_tuesday.day.to_s.rjust(2, '0')}\.#{next_tuesday.month.to_s.rjust(2, '0')}\./
        expect(page).to have_css(tue_css_selector, text: expected)
      end
    end
  end
end
