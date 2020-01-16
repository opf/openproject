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

require_relative '../spec_helper'

describe 'Global role: Global Create project', type: :feature, js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create :project }

  before do
    login_as(user)
  end

  describe 'Create Project is not a member permission' do
    # Given there is a role "Member"
    let!(:role) { FactoryBot.create(:role, name: 'Member') }

    # And I am already admin
    # When I go to the edit page of the role "Member"
    # Then I should not see "Create project"
    it 'does not show the global permission' do
      visit edit_role_path(role)
      expect(page).to have_selector('.form--label-with-check-box', text: 'Edit project')
      expect(page).to have_no_selector('.form--label-with-check-box', text: 'Create project')
    end
  end

  describe 'Create Project is a global permission' do
    # Given there is a global role "Global"
    let!(:role) { FactoryBot.create(:global_role, name: 'Global') }
    # And I am already admin
    # When I go to the edit page of the role "Global"
    # Then I should see "Create project"
    it 'does show the global permission' do
      visit edit_role_path(role)
      expect(page).to have_no_selector('.form--label-with-check-box', text: 'Edit project')
      expect(page).to have_selector('.form--label-with-check-box', text: 'Create project')
    end
  end

  describe 'Create Project displayed to user' do
    # Given there is a global role "Global"
    let!(:global_role) { FactoryBot.create(:global_role, name: 'Global', permissions: %i[add_project]) }
    let!(:member_role) { FactoryBot.create(:role, permissions: %i[]) }
    # And the global role "Global" may have the following rights:
    # And the user "bob" has the global role "Global"
    let(:user) { FactoryBot.create :user }
    let!(:principal_role) { FactoryBot.create(:principal_role, principal: user, role: global_role) }
    # When I am already logged in as "bob"
    it 'does show the global permission' do
      # And I go to the overall projects page
      visit projects_path
      # Then I should see "Project" within ".toolbar-items
      expect(page).to have_selector('.button.-alt-highlight', text: 'Project')

      # Can add new project
      visit new_project_path

      fill_in 'project_name', with: 'New project name'
      click_on 'Create'

      expect(page).to have_text 'Successful creation.'
      expect(current_path).to match /projects\/new-project-name/
    end
  end

  describe 'Create Project not displayed to user without global role' do
    # Given there is 1 User with:
    # | Login | bob |
    # | Firstname | Bob |
    # | Lastname | Bobbit |
    #   When I am already logged in as "bob"
    let(:user) { FactoryBot.create :user }
    it 'does show the global permission' do
      # And I go to the overall projects page
      visit projects_path
      # Then I should not see "Project" within ".toolbar-items"
      expect(page).to have_no_selector('.button.-alt-highlight', text: 'Project')
    end
  end
end
