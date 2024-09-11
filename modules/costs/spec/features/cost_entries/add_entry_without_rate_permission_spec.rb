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

require_relative "../../spec_helper"

RSpec.describe "Create cost entry without rate permissions", :js do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:project) do
    create(:project, types: [type_task])
  end
  shared_let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           log_costs
                           view_cost_entries
                           work_package_assigned])
  end
  shared_let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  shared_let(:cost_type) do
    type = create(:cost_type, name: "A", unit: "A single", unit_plural: "A plural")
    create(:cost_rate, cost_type: type, rate: 1.00)
    type
  end

  shared_let(:work_package) { create(:work_package, project:, status:, type: type_task) }
  shared_let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as user
  end

  it "can create the item without seeing the costs" do
    full_view.visit!
    # Go to add cost entry page
    SeleniumHubWaiter.wait
    find("#action-show-more-dropdown-menu .button").click
    find(".menu-item", text: "Log unit costs").click

    SeleniumHubWaiter.wait
    # Set single value, should update suffix
    select "A", from: "cost_entry_cost_type_id"
    fill_in "cost_entry_units", with: "1"
    expect(page).to have_css("#cost_entry_unit_name", text: "A single")
    expect(page).to have_no_css("#cost_entry_costs")

    click_on "Save"

    # Expect correct costs
    expect(page).to have_css(".op-toast.-success", text: I18n.t(:notice_cost_logged_successfully))
    entry = CostEntry.last
    expect(entry.cost_type_id).to eq(cost_type.id)
    expect(entry.units).to eq(1.0)
    expect(entry.costs).to eq(1.0)
    expect(entry.real_costs).to eq(1.0)
  end
end
