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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"
require_relative "support/pages/cost_report_page"

RSpec.describe "Cost reports XLS export", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin, preferences: { time_zone: "UTC" }) }
  shared_let(:cost_type) { create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps") }
  shared_let(:work_package) { create(:work_package, project:, subject: "Some task") }
  shared_let(:cost_entry) do
    create(:cost_entry, user:, entity: work_package, project:,
                        cost_type:, spent_on: 3.days.ago)
  end
  shared_let(:time_entry) do
    create(:time_entry, user:, entity: work_package, project:,
                        start_time: 1 * 60,
                        spent_on: 2.days.ago,
                        hours: 1.95,
                        time_zone: "UTC")
  end
  shared_let(:time_entry_long) do
    create(:time_entry, user:, entity: work_package, project:,
                        start_time: 1 * 60,
                        spent_on: 1.day.ago,
                        hours: 28.0,
                        time_zone: "UTC")
  end

  let(:report_page) { Pages::CostReportPage.new project }
  let(:sheet) { @download_list.refresh_from(page).latest_downloaded_content } # rubocop:disable RSpec/InstanceVariable

  subject do
    io = StringIO.new sheet
    Spreadsheet.open(io).worksheets
  end

  before do
    @download_list = DownloadList.new
    login_as(user)
  end

  after do
    DownloadList.clear
  end

  def excel_float_to_date(excel_float)
    (DateTime.new(1899, 12, 30) + excel_float).to_date
  end

  def expect_custom_cost_entry(cost_entry_row, entry)
    date, user_ref, _, wp_ref, _, project_ref, costs, type, = cost_entry_row
    expect(excel_float_to_date(date)).to eq(entry.spent_on)
    expect(user_ref).to eq(user.name)
    expect(wp_ref).to include "Some task"
    expect(project_ref).to eq project.name
    expect(costs).to eq 1.0
    expect(type).to eq "Post-war"
  end

  def expect_labor_cost_entry(cost_entry_row, entry)
    date, user_ref, _, wp_ref, _, project_ref, costs, type, = cost_entry_row
    expect(excel_float_to_date(date)).to eq(entry.spent_on)
    expect(user_ref).to eq(user.name)
    expect(wp_ref).to include "Some task"
    expect(project_ref).to eq project.name
    expect(costs).to eq entry.hours
    expect(type).to eq "Labor"
  end

  def expect_time_entry(time_entry_row, entry, start_time_value, end_time_value)
    date, start_time, end_time, user_ref, _, wp_ref, _, project_ref, costs, type, = time_entry_row
    expect(excel_float_to_date(date)).to eq(entry.spent_on)
    expect(start_time).to eq start_time_value
    expect(end_time).to eq end_time_value
    expect(user_ref).to eq(user.name)
    expect(wp_ref).to include "Some task"
    expect(project_ref).to eq project.name
    expect(costs).to eq entry.hours
    expect(type).to eq "Labor"
  end

  def expect_sheet_title(title)
    expect(title.first).to include("Cost reports (#{Time.zone.today.strftime('%m/%d/%Y')})")
  end

  def expect_cost_entries_sheet
    title, _, cost_entry_row, time_entry_row, time_entry_long_row = subject.first.rows
    expect_sheet_title title
    expect_custom_cost_entry cost_entry_row, cost_entry
    expect_labor_cost_entry time_entry_row, time_entry
    expect_labor_cost_entry time_entry_long_row, time_entry_long
  end

  def expect_time_entries_sheet(allow_show_start_and_end_times)
    title, _, time_entry_row, time_entry_long_row = subject.second.rows
    expect_sheet_title title
    if allow_show_start_and_end_times
      expect_time_entry time_entry_row, time_entry, "01:00 AM", "02:57 AM"
      expect_time_entry time_entry_long_row, time_entry_long, "01:00 AM",
                        "#{(time_entry_long.spent_on + 1.day).iso8601} 05:00 AM"
    else
      expect_labor_cost_entry time_entry_row, time_entry
      expect_labor_cost_entry time_entry_long_row, time_entry_long
    end
  end

  def expect_custom_type_entries_sheet
    title, _, cost_entry_row = subject.third.rows
    expect_sheet_title title
    expect_custom_cost_entry cost_entry_row, cost_entry
  end

  def export_xls
    report_page.visit!
    click_on "Export XLS"

    expect(page).to have_content I18n.t("job_status_dialog.generic_messages.in_queue"),
                                 wait: 10
    perform_enqueued_jobs

    expect(page).to have_text(I18n.t("export.succeeded"))
  end

  context "with allow_tracking_start_and_end_times", with_settings: { allow_tracking_start_and_end_times: true } do
    it "can download and open the XLS" do
      export_xls
      expect_cost_entries_sheet
      expect_time_entries_sheet true
      expect_custom_type_entries_sheet
    end
  end

  context "without allow_tracking_start_and_end_times", with_settings: { allow_tracking_start_and_end_times: false } do
    it "can download and open the XLS" do
      export_xls
      expect_cost_entries_sheet
      expect_time_entries_sheet false
      expect_custom_type_entries_sheet
    end
  end
end
