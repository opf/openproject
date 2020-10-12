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

feature 'group memberships through groups page', type: :feature, js: true do
  using_shared_fixtures :admin
  let!(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }

  let!(:peter)    { FactoryBot.create :user, firstname: 'Peter', lastname: 'Pan', mail: 'foo@example.org' }
  let!(:hannibal) { FactoryBot.create :user, firstname: 'Hannibal', lastname: 'Smith', mail: 'boo@bar.org' }
  let!(:crash)    { FactoryBot.create :user, firstname: "<script>alert('h4x');</script>",
                                              lastname: "<script>alert('h4x');</script>" }

  let(:group) { FactoryBot.create :group, lastname: 'A-Team' }

  let!(:manager)   { FactoryBot.create :role, name: 'Manager' }
  let!(:developer) { FactoryBot.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin

    group.add_members! peter
    group.add_members! hannibal
  end

  shared_examples 'adding and removing principals' do
    scenario 'Adding and Removing a Group as Member' do
      members_page.visit!
      members_page.add_user! 'A-Team', as: 'Manager'

      expect(members_page).to have_added_group('A-Team')

      members_page.remove_group! 'A-Team'
      expect(page).to have_text 'Removed A-Team from project'
      expect(page).to have_text 'There are currently no members part of this project.'
    end

    scenario 'Adding and removing a User as Member' do
      members_page.visit!
      members_page.add_user! 'Hannibal Smith', as: 'Manager'

      expect(members_page).to have_added_user 'Hannibal Smith'

      members_page.remove_user! 'Hannibal Smith'
      expect(page).to have_text 'Removed Hannibal Smith from project'
      expect(page).to have_text 'There are currently no members part of this project.'
    end

    scenario 'Entering a Username as Member in firstname, lastname order' do
      members_page.visit!
      members_page.open_new_member!

      members_page.search_principal! 'Hannibal S'
      expect(members_page).to have_search_result 'Hannibal Smith'
    end

    scenario 'Entering a Username as Member in lastname, firstname order' do
      members_page.visit!
      members_page.open_new_member!

      members_page.search_principal! 'Smith, H'
      expect(members_page).to have_search_result 'Hannibal Smith'
    end

    scenario 'Escaping should work properly when entering a name' do
      members_page.visit!
      members_page.open_new_member!
      members_page.search_principal! 'script'

      expect(members_page).not_to have_alert_dialog
      expect(members_page).to have_search_result "<script>alert('h4x');</script>"
    end
  end

  context 'with members in the project' do
    let!(:member1) { FactoryBot.create(:member, principal: peter, project: project, roles: [manager]) }
    let!(:member2) { FactoryBot.create(:member, principal: hannibal, project: project, roles: [developer]) }
    let!(:member3) { FactoryBot.create(:member, principal: group, project: project, roles: [manager]) }

    scenario 'sorting the page' do
      members_page.visit!

      members_page.sort_by 'last name'
      members_page.expect_sorted_by 'last name'

      expect(members_page.contents('lastname')).to eq ['', peter.lastname, hannibal.lastname]

      members_page.sort_by 'last name'
      members_page.expect_sorted_by 'last name', desc: true
      expect(members_page.contents('lastname')).to eq [hannibal.lastname, peter.lastname, '']

      members_page.sort_by 'first name'
      members_page.expect_sorted_by 'first name'
      expect(members_page.contents('firstname')).to eq ['', hannibal.firstname, peter.firstname]

      members_page.sort_by 'email'
      members_page.expect_sorted_by 'email'
      expect(members_page.contents('email')).to eq ['', hannibal.mail, peter.mail]

      # Cannot sort by group, roles or status
      expect(page).to have_no_selector('.generic-table--sort-header a', text: 'ROLES')
      expect(page).to have_no_selector('.generic-table--sort-header a', text: 'GROUP')
      expect(page).to have_no_selector('.generic-table--sort-header a', text: 'STATUS')
    end
  end

  context 'with a user' do
    it_behaves_like 'adding and removing principals'

    scenario 'Escaping should work properly when selecting a user' do
      members_page.visit!
      members_page.open_new_member!
      members_page.select_principal! 'script'

      expect(members_page).not_to have_alert_dialog
      expect(page).to have_text "<script>alert('h4x');</script>"
    end
  end
end
