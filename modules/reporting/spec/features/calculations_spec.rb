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

require "spec_helper"

RSpec.describe "Cost Report", "calculations", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package, project:) }

  def create_hourly_rates
    create(:default_hourly_rate, user:, rate: 1.00,  valid_from: 1.year.ago)
    create(:default_hourly_rate, user:, rate: 5.00,  valid_from: 2.years.ago)
    create(:default_hourly_rate, user:, rate: 10.00, valid_from: 3.years.ago)
  end

  def create_time_entries_on(*timestamps_of_recordings)
    timestamps_of_recordings.each do |spent_on|
      create(:time_entry,
             spent_on:,
             user:,
             entity: work_package,
             project:,
             hours: 10)
    end
  end

  before do
    create_hourly_rates
    create_time_entries_on(6.months.ago, 18.months.ago, 30.months.ago)
    login_as user
    visit reporting_cost_reports_path(filters: "")
  end

  it "shows the correct calculations" do
    expect(page).to have_text "10.00"  # 1  EUR x 10
    expect(page).to have_text "50.00"  # 5  EUR x 10
    expect(page).to have_text "100.00" # 10 EUR x 10
    expect(page).to have_text "160.00" # Total
  end
end
