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

RSpec.describe "Cost report showing my own times", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:user2) { create(:admin) }

  let(:work_package) { create(:work_package, project:) }
  let!(:hourly_rate1) { create(:default_hourly_rate, user:, rate: 1.00, valid_from: 1.year.ago) }

  let!(:time_entry1) do
    create(:time_entry,
           user:,
           entity: work_package,
           project:,
           hours: 10)
  end

  before do
    login_as(current_user)
    visit project_reporting_cost_reports_path(project)
  end

  context "as user with logged time" do
    let(:current_user) { user }

    it "shows my time" do
      expect(page).to have_css(".report", text: "10.0")
    end
  end

  context "as user without logged time" do
    let(:current_user) { user2 }

    it "shows my time" do
      expect(page).to have_no_css(".report")
      expect(page).to have_css(".generic-table--no-results-title")
      expect(page).to have_no_text "10.0" # 1 EUR x 10
    end
  end
end
