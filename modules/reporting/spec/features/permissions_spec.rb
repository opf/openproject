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
require_relative "support/pages/cost_report_page"

RSpec.describe "Cost report calculations", :js do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }

  let!(:permissions) { %i(view_cost_entries view_own_cost_entries) }
  let!(:role) { create(:project_role, permissions:) }
  let!(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let(:work_package) { create(:work_package, project:) }
  let!(:hourly_rate_admin) { create(:default_hourly_rate, user: admin, rate: 1.00, valid_from: 1.year.ago) }
  let!(:hourly_rate_user) { create(:default_hourly_rate, user:, rate: 1.00, valid_from: 1.year.ago) }

  let(:report_page) { Pages::CostReportPage.new project }

  let!(:time_entry_user) do
    create(:time_entry,
           user: admin,
           entity: work_package,
           project:,
           hours: 10)
  end
  let!(:time_entry_admin) do
    create(:time_entry,
           user:,
           entity: work_package,
           project:,
           hours: 5)
  end
  let!(:cost_type) do
    type = create(:cost_type, name: "Translations")
    create(:cost_rate, cost_type: type, rate: 7.00)
    type
  end
  let!(:cost_entry_user) do
    create(:cost_entry,
           entity: work_package,
           project: project,
           units: 3.00,
           cost_type:,
           user:)
  end

  before do
    login_as current_user
    visit reporting_cost_reports_path(filters: "")
  end

  context "as anonymous" do
    let(:current_user) { User.anonymous }

    it "is redirect to login" do
      expect(page).to have_content "Username"
      expect(page).to have_content "Password"
    end
  end

  context "as admin" do
    let(:current_user) { admin }

    it "shows everything" do
      expect(page).to have_content "5.00 hours"
      expect(page).to have_content "10.00 hours"

      report_page.switch_to_type "Translations"

      expect(page).to have_content "3.0 plural_unit"
      expect(page).to have_content "21.00 €"
    end
  end

  context "as user with all permissions" do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_hourly_rate view_hourly_rates view_cost_rates
         view_own_time_entries view_own_cost_entries view_cost_entries
         view_time_entries)
    end

    it "shows everything" do
      expect(page).to have_content "5.00 hours"
      expect(page).to have_content "10.00 hours"
      report_page.switch_to_type "Translations"
      expect(page).to have_css("td.units", text: "3.0 plural_unit", wait: 10)
    end
  end

  context "as user with no permissions" do
    let(:current_user) { user }
    let!(:permissions) { %i() }

    it "shows nothing" do
      expect(page).to have_text "[Error 403]"
    end
  end

  context "as user with own permissions" do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_hourly_rate view_own_time_entries view_own_cost_entries)
    end

    it "shows his own costs" do
      expect(page).to have_content "5.00 hours"
      expect(page).to have_no_content "10.00 hours"
      report_page.switch_to_type "Translations"
      expect(page).to have_css("td.units", text: "3.0 plural_unit", wait: 10)
    end
  end

  context "as user with own time permissions" do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_time_entries)
    end

    it "shows his own time only" do
      expect(page).to have_content "5.00 hours"
      expect(page).to have_no_content "10.00 hours"

      report_page.switch_to_type "Translations"
      expect(page).to have_css(".generic-table--no-results-title")
      expect(page).to have_no_css("td.unit", text: "3.0 plural_unit")
    end
  end

  context "as user with own costs permissions" do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_cost_entries)
    end

    it "shows his own costs" do
      expect(page).to have_css(".generic-table--no-results-title")
      expect(page).to have_no_content "5.00 hours"
      expect(page).to have_no_content "10.00 hours"
      report_page.switch_to_type "Translations"
      expect(page).to have_no_css("td.unit", text: "3.0 plural_unit")
    end
  end
end
