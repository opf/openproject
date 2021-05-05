#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'members pagination', type: :feature, js: true do
  shared_let(:admin) { FactoryBot.create :admin }
  let(:project) do
    FactoryBot.create :project,
                      name: 'Project 1',
                      identifier: 'project1',
                      members: project_members
  end
  let(:project_members) {
    {
      bob => manager,
      alice => developer
    }
  }

  let!(:peter) { FactoryBot.create :user, firstname: 'Peter', lastname: 'Pan' }
  let(:bob)   { FactoryBot.create :user, firstname: 'Bob', lastname: 'Bobbit' }
  let(:alice) { FactoryBot.create :user, firstname: 'Alice', lastname: 'Alison' }

  let(:manager)   { FactoryBot.create :role, name: 'Manager' }
  let(:developer) { FactoryBot.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }

  current_user { admin }

  context 'when adding a member' do
    it 'paginates' do
      members_page.set_items_per_page! 2

      members_page.visit!
      SeleniumHubWaiter.wait
      expect(members_page).to have_user 'Alice Alison' # members are sorted by last name desc
      members_page.add_user! 'Peter Pan', as: 'Manager'

      SeleniumHubWaiter.wait
      members_page.go_to_page! 2
      expect(members_page).to have_user 'Peter Pan'
    end
  end

  context 'when removing a member' do
    let(:project_members) {
      {
        bob => manager,
        alice => developer,
        peter => manager
      }
    }

    it 'paginates' do
      members_page.set_items_per_page! 1

      members_page.visit!
      SeleniumHubWaiter.wait
      members_page.remove_user! 'Alice Alison'
      expect(members_page).to have_user 'Bob Bobbit'

      SeleniumHubWaiter.wait
      members_page.go_to_page! 2
      expect(members_page).to have_user 'Peter Pan'
    end
  end

  context 'when updating a member' do
    it 'paginates' do
      members_page.set_items_per_page! 1

      members_page.visit!
      SeleniumHubWaiter.wait
      members_page.go_to_page! 2
      members_page.edit_user! 'Bob Bobbit', add_roles: ['Developer']
      expect(page).to have_text 'Successful update'
      expect(members_page).to have_user 'Bob Bobbit', roles: ['Developer', 'Manager']

      SeleniumHubWaiter.wait
      members_page.go_to_page! 1
      expect(members_page).to have_user 'Alice Alison'
    end
  end
end
