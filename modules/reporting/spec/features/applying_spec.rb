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
require_relative "support/pages/cost_report_page"

RSpec.describe "Cost report page apply", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:report_page) { Pages::CostReportPage.new project }

  before do
    login_as user
    visit project_reporting_cost_reports_path(project)
    report_page.save as: "Testreport"
  end

  def clear_project_filter
    within "#filter_project_id" do
      find(".filter_rem").click
    end
  end

  def reload_page
    page.refresh
    wait_for_reload
  end

  it "applying does not save a report" do
    # we load our report
    click_on "Testreport"

    # we have project filter
    expect(page).to have_css("#filter_project_id")

    # we remove it
    clear_project_filter

    # must be gone
    expect(page).to have_no_css("#filter_project_id")

    # press Apply
    report_page.apply

    # reload report
    click_on "Testreport"

    # must be present
    expect(page).to have_css("#filter_project_id")
  end
end
