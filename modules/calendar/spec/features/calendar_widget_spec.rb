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
require_relative "../../../overviews/spec/support/pages/overview"
require_relative "../support/pages/calendar"

RSpec.describe "Calendar Widget", :js, :with_cuprite, with_settings: { start_of_week: 1 } do
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
    create(:structured_meeting, title: "Weekly", project:, start_time: Time.zone.tomorrow + 10.hours)
  end

  let(:overview_page) do
    Pages::Overview.new(project)
  end
  let(:wp_full_view) { Pages::FullWorkPackage.new(work_package, project) }
  let(:calendar) { Pages::Calendar.new project }

  shared_let(:current_user) do
    create(:user,
           member_with_permissions: {
             project => %w[view_work_packages view_meetings edit_work_packages view_calendar manage_overview]
           })
  end

  before do
    login_as(current_user)
    overview_page.visit!

    wait_for_network_idle if RSpec.current_example.metadata[:with_cuprite]

    # within top-left area, add an additional widget
    overview_page.add_widget(1, 1, :row, "Calendar")

    overview_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")
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
               project => %w[view_work_packages view_meetings edit_work_packages view_calendar manage_overview]
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

  it "opens the work package full view when clicking a calendar entry" do
    # Clicking the calendar entry goes to work package full screen
    page.find(".fc-event-title", text: work_package.subject).click
    wp_full_view.ensure_page_loaded

    wp_full_view.go_back
    expect(page).to have_text("Overview")
  end

  it "can resize the same work package twice (Regression #48333)", with_cuprite: false do
    expect(page).to have_css(".fc-event-title", text: work_package.subject)

    calendar.resize_date(work_package, work_package.due_date - 1.day)
    overview_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload
    expect(work_package.due_date).to eq Time.zone.today.beginning_of_week.next_occurring(:wednesday)

    calendar.resize_date(work_package, work_package.due_date - 1.day)
    overview_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    work_package.reload
    expect(work_package.due_date).to eq Time.zone.today.beginning_of_week.next_occurring(:tuesday)
  end
end
