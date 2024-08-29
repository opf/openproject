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
require_relative "mock_global_permissions"

RSpec.describe "Global role: Global role CRUD", :js, :with_cuprite do
  # Scenario: Global Role creation
  # Given there is the global permission "glob_test" of the module "global_group"
  include_context "with mocked global permissions", [["glob_test", { project_module: "global_group" }]]

  before do
    login_as current_user
  end

  current_user { create(:admin) }

  it "can create global role with that perm" do
    # When I go to the new page of "Role"
    visit new_role_path
    # Then I should not see block with "#global_permissions"
    expect(page).to have_no_css(".form--fieldset-legend", text: "GLOBAL")
    # When I check "Global role"
    check "Global role"
    # Then I should see block with "#global_permissions"
    expect(page).to have_css(".form--fieldset-legend", text: "GLOBAL")
    # And I should see "Global group"
    expect(page).to have_text "GLOBAL GROUP"
    # And I should see "Glob test"
    expect(page).to have_text "Glob test"
    # And I should not see "Issues can be assigned to this role"
    expect(page).to have_no_text "Issues can be assigned to this role"
    # When I fill in "Name" with "Manager"
    fill_in "Name", with: "Manager"
    # And I click on "Create"
    click_on "Create"
    # Then I should see "Successful creation."
    expect(page).to have_text "Successful creation."
  end
end
