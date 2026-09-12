# frozen_string_literal: true

#
# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Cost report date filter", :js do
  let(:project) { create(:project) }

  let(:work_package1) { create(:work_package, project:) }
  let(:work_package2) { create(:work_package, project:) }
  let(:work_package3) { create(:work_package, project:) }

  let!(:today_time_entry) { create(:time_entry, entity: work_package1, hours: 5) }
  let!(:five_days_ago_time_entry) { create(:time_entry, entity: work_package2, hours: 10, spent_on: 5.days.ago) }
  let!(:five_days_from_now_time_entry) { create(:time_entry, entity: work_package3, hours: 15, spent_on: 5.days.from_now) }

  current_user { create(:admin) }

  before do
    visit project_reporting_cost_reports_path(project)
  end

  it "filters the time entries" do
    # Remove filters not tested here but added by default
    find_by_id("rm_box_user_id").click
    find_by_id("rm_box_project_id").click

    # 'Date (spent on)' filter is also selected by default
    select "today", from: "operators[spent_on]"
    click_link "Apply"

    expect(page).to have_content(today_time_entry.hours)
    expect(page).to have_content(today_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_ago_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_from_now_time_entry.entity.subject)

    select "<=", from: "operators[spent_on]"
    fill_in "spent_on_arg_1_val", with: 4.days.ago.iso8601
    click_link "Apply"

    expect(page).to have_content(five_days_ago_time_entry.hours)
    expect(page).to have_content(five_days_ago_time_entry.entity.subject)
    expect(page).to have_no_content(today_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_from_now_time_entry.entity.subject)

    select "during the last days", from: "operators[spent_on]"
    fill_in "spent_on_arg_1_integers_val", with: "5"
    click_link "Apply"

    expect(page).to have_content(five_days_ago_time_entry.hours)
    expect(page).to have_content(five_days_ago_time_entry.entity.subject)
    expect(page).to have_content(today_time_entry.hours)
    expect(page).to have_content(today_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_from_now_time_entry.entity.subject)

    select ">=", from: "operators[spent_on]"
    fill_in "spent_on_arg_1_val", with: 4.days.from_now.iso8601
    click_link "Apply"

    expect(page).to have_content(five_days_from_now_time_entry.hours)
    expect(page).to have_content(five_days_from_now_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_ago_time_entry.entity.subject)
    expect(page).to have_no_content(today_time_entry.entity.subject)

    select "between", from: "operators[spent_on]"
    fill_in "spent_on_arg_1_val", with: 4.days.ago.iso8601
    fill_in "spent_on_arg_2_val", with: 4.days.from_now.iso8601
    click_link "Apply"

    expect(page).to have_content(today_time_entry.hours)
    expect(page).to have_content(today_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_ago_time_entry.entity.subject)
    expect(page).to have_no_content(five_days_from_now_time_entry.entity.subject)
  end
end
