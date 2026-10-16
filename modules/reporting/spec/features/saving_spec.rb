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
require_relative "support/pages/cost_report_page"

RSpec.describe "Cost report saving", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  let(:report_page) { Pages::CostReportPage.new project }

  before do
    login_as(user)
    visit project_reporting_cost_reports_path(project)
  end

  it "can save reports privately" do
    report_page.clear

    report_page.add_to_columns "Work package"
    report_page.add_to_rows "Project"

    report_page.save as: "Testreport"

    # Check if the category is displayed
    expect(page).to have_css(".op-submenu--title", text: I18n.t(:label_private_report_plural))
    # Check if the new report is displayed
    expect(page).to have_css(".op-submenu--item-title", text: "Testreport")

    report_page.expect_column_element "Work package"
    report_page.expect_row_element "Project"
  end

  it "can save reports publicly" do
    report_page.clear

    report_page.add_to_columns "Work package"
    report_page.add_to_rows "Project"

    report_page.save as: "Public report", public: true

    # Check if the category is displayed
    expect(page).to have_css(".op-submenu--title", text: I18n.t(:label_public_report_plural))
    # Check if the new report is displayed
    expect(page).to have_css(".op-submenu--item-title", text: "Public report")

    report_page.expect_column_element "Work package"
    report_page.expect_row_element "Project"
  end

  context "as user without permissions" do
    let(:role) { create(:project_role, permissions: %i(view_time_entries)) }
    let!(:user) do
      create(:user,
             member_with_roles: { project => role })
    end

    it "cannot save reports" do
      expect(page).to have_no_css(".buttons", text: "Save")
    end
  end
end
