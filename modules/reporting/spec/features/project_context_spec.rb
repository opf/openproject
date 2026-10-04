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

RSpec.describe "Cost report project context", :js do
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:admin) { create(:admin) }

  let(:report_page) { Pages::CostReportPage.new project }

  before do
    project1
    project2
    login_as admin
  end

  it "switches the project context when visiting another project's cost report" do
    visit project_reporting_cost_reports_path(project1)
    expect(page).to have_css(".ng-value-label", text: project1.name)

    visit project_reporting_cost_reports_path(project2)
    expect(page).to have_css(".ng-value-label", text: project2.name)
  end
end
