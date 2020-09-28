#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './mock_global_permissions'

describe 'Global role: Global role assignment', type: :feature, js: true do
  before do
    login_as(current_user)
  end

  describe 'Going to the global role assignment page' do
    before do
      mock_global_permissions [['global1', project_module: :global], ['global2', project_module: :global]]
    end
    let!(:global_role1) { FactoryBot.create :global_role, name: 'global_role1', permissions: %i[global1] }
    let!(:global_role2) { FactoryBot.create :global_role, name: 'global_role2', permissions: %i[global2] }

    let!(:user) { FactoryBot.create :user }
    let!(:global_member) do
      FactoryBot.create(:global_member,
                        principal: user,
                        roles: [global_role1])
    end

    let(:current_user) { FactoryBot.create :admin }

    it 'allows global roles management' do
      visit edit_user_path user
      click_link 'Global Roles'

      page.within('#table_principal_roles') do
        expect(page).to have_text 'global_role1'
      end
      # And I should not see "global_role1" within "#available_principal_roles"
      # And I should see "global_role2" within "#available_principal_roles"
      page.within('#available_principal_roles') do
        expect(page).to have_no_text 'global_role1'
        expect(page).to have_text 'global_role2'
      end

      # And I select the available global role "global_role"
      check 'global_role2'
      # And I press "Add"
      click_on 'Add'

      # Then I should see "global_role" within "#table_principal_roles"
      page.within('#available_principal_roles') do
        expect(page).to have_no_text 'global_role1'
        expect(page).to have_no_text 'global_role2'
      end
      # And I should not see "global_role" within "#available_principal_roles"
      # And I should see "There is currently nothing to display"
      page.within('#table_principal_roles') do
        expect(page).to have_text 'global_role1'
        expect(page).to have_text 'global_role2'
      end

      # And I delete the assigned role "global_role"
      page.within("#assigned_global_role_#{global_role1.id}") do
        page.find('.buttons a.icon-delete').click
      end

      # Then I should see "global_role" within "#table_principal_roles"
      page.within('#available_principal_roles') do
        expect(page).to have_text 'global_role1'
        expect(page).to have_no_text 'global_role2'
      end
      # And I should not see "global_role" within "#available_principal_roles"
      # And I should see "There is currently nothing to display"
      page.within('#table_principal_roles') do
        expect(page).to have_no_text 'global_role1'
        expect(page).to have_text 'global_role2'
      end
    end
  end
end
