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

RSpec.describe "Global role: Global role assignment", :js, :with_cuprite do
  before do
    login_as current_user
  end

  describe "Going to the global role assignment page" do
    include_context "with mocked global permissions",
                    [["global1", { project_module: :global }], ["global2", { project_module: :global }]]

    let!(:global_role1) { create(:global_role, name: "global_role1", permissions: %i[global1]) }
    let!(:global_role2) { create(:global_role, name: "global_role2", permissions: %i[global2]) }

    let!(:user) { create(:user) }
    let!(:global_member) do
      create(:global_member,
             principal: user,
             roles: [global_role1])
    end

    let(:current_user) { create(:admin) }

    it "allows global roles management" do
      visit edit_user_path user
      click_link "Global roles"

      page.within("#table_principal_roles") do
        expect(page).to have_text "global_role1"
      end
      # And I should not see "global_role1" within "#available_principal_roles"
      # And I should see "global_role2" within "#available_principal_roles"
      page.within("#available_principal_roles") do
        expect(page).to have_no_text "global_role1"
        expect(page).to have_text "global_role2"
      end

      # And I select the available global role "global_role2"
      check "global_role2"
      # And I press "Add"
      click_on "Add"

      wait_for_network_idle

      # And I should see "global_role1" within "#table_principal_roles"
      # Then I should see "global_role2" within "#table_principal_roles"
      page.within("#table_principal_roles") do
        expect(page).to have_text "global_role1"
        expect(page).to have_text "global_role2"
      end

      # And I should not see "global_role1" within "#available_principal_roles"
      # And I should not see "global_role2" within "#available_principal_roles"
      page.within("#available_principal_roles") do
        expect(page).to have_no_text "global_role1"
        expect(page).to have_no_text "global_role2"
      end

      # And I delete the assigned role "global_role1"
      page.within("#assigned_global_role_#{global_role1.id}") do
        page.find(".buttons a.icon-delete").click
      end

      wait_for_network_idle

      # Then I should see "global_role1" within "#available_principal_roles"
      # And I should not see "global_role2" within "#available_principal_roles"
      page.within("#available_principal_roles") do
        expect(page).to have_text "global_role1"
        expect(page).to have_no_text "global_role2"
      end

      # And I should not see "global_role1" within "#table_principal_roles"
      # And I should see "global_role1" within "#table_principal_roles"
      page.within("#table_principal_roles") do
        expect(page).to have_no_text "global_role1"
        expect(page).to have_text "global_role2"
      end
    end
  end
end
