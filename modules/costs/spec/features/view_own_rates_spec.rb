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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

RSpec.describe "Only see your own rates", :js do
  let(:project) { work_package.project }
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role, permissions: %i[view_own_hourly_rate
                                          view_work_packages
                                          view_work_packages
                                          view_own_time_entries
                                          view_own_cost_entries
                                          view_cost_rates
                                          log_costs])
  end
  let(:work_package) { create(:work_package) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:hourly_rate) do
    create(:default_hourly_rate, user:,
                                 rate: 10.00)
  end
  let(:time_entry) do
    create(:time_entry, user:,
                        work_package:,
                        project:,
                        hours: 1.00)
  end
  let(:cost_type) do
    type = create(:cost_type, name: "Translations")
    create(:cost_rate, cost_type: type,
                       rate: 7.00)
    type
  end
  let(:cost_entry) do
    create(:cost_entry, work_package:,
                        project:,
                        units: 2.00,
                        cost_type:,
                        user:)
  end
  let(:other_role) { create(:project_role, permissions: []) }
  let(:other_user) do
    create(:user,
           member_with_roles: { project => other_role })
  end
  let(:other_hourly_rate) do
    create(:default_hourly_rate, user: other_user,
                                 rate: 11.00)
  end
  let(:other_time_entry) do
    create(:time_entry, user: other_user,
                        hours: 3.00,
                        project:,
                        work_package:)
  end
  let(:other_cost_entry) do
    create(:cost_entry, work_package:,
                        project:,
                        units: 5.00,
                        user: other_user,
                        cost_type:)
  end

  before do
    login_as(user)

    work_package
    hourly_rate
    time_entry
    cost_entry
    other_hourly_rate
    other_user
    other_time_entry
    other_cost_entry

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "only displays own entries and rates" do
    # All the values do not include the entries made by the other user
    wp_page.expect_attributes spent_time: "1h",
                              costs_by_type: "2 Translations",
                              overall_costs: "24.00 EUR",
                              labor_costs: "10.00 EUR",
                              material_costs: "14.00 EUR"
  end
end
