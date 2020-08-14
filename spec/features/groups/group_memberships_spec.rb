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

  let!(:peter)    { FactoryBot.create :user, firstname: 'Peter', lastname: 'Pan' }
  let!(:hannibal) { FactoryBot.create :user, firstname: 'Hannibal', lastname: 'Smith' }
  let(:group)     { FactoryBot.create :group, lastname: 'A-Team' }

  let!(:manager)   { FactoryBot.create :role, name: 'Manager' }
  let!(:developer) { FactoryBot.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }
  let(:group_page)   { Pages::Groups.new.group(group.id) }

  before do
    allow(User).to receive(:current).and_return admin

    group.add_members! peter
  end

  scenario 'adding a user to a group adds the user to the project as well' do
    members_page.visit!
    expect(members_page).not_to have_user 'Hannibal Smith'

    group_page.visit!
    group_page.add_to_project! 'Project 1', as: 'Manager'
    expect(page).to have_text 'Successful update'

    group_page.add_user! 'Hannibal'

    members_page.visit!
    expect(members_page).to have_group 'A-Team', roles: ['Manager']
    expect(members_page).to have_user 'Peter Pan', roles: ['Manager']
    expect(members_page).to have_user 'Hannibal Smith', roles: ['Manager']
  end

  context 'given a group with members in a project' do
    before do
      group.add_members! hannibal
      project.add_member! group, [manager]
    end

    scenario 'removing a user from the group removes them from the project too' do
      members_page.visit!
      expect(members_page).to have_user 'Hannibal Smith'

      group_page.visit!
      group_page.remove_user! 'Hannibal Smith'

      members_page.visit!
      expect(members_page).to have_user 'A-Team'
      expect(members_page).to have_user 'Peter Pan'
      expect(members_page).not_to have_user 'Hannibal Smith'
    end

    scenario 'removing the group from a project' do
      group_page.visit!
      group_page.open_projects_tab!
      expect(group_page).to have_project 'Project 1'

      group_page.remove_from_project! 'Project 1'
      expect(page).to have_text 'Successful deletion'
      expect(page).to have_text 'There are currently no projects part of this group.'
    end
  end

  describe 'with the group in two projects' do
    let!(:project2) { FactoryBot.create :project, name: 'Project 2', identifier: 'project2' }
    let(:members_page1) { Pages::Members.new project.identifier }
    let(:members_page2) { Pages::Members.new project2.identifier }

    before do
      project.add_member! peter, [manager]
      project2.add_member! peter, [manager]

      project.add_member! group, [developer]
      project2.add_member! group, [developer]
    end

    it 'can add a new user to the group with correct member roles (Regression #33659)' do
      members_page1.visit!

      expect(members_page1).to have_group 'A-Team', roles: [developer]
      expect(members_page1).to have_user 'Peter Pan', roles: [manager, developer]
      expect(members_page1).not_to have_user 'Hannibal Smith'

      members_page2.visit!

      expect(members_page2).to have_group 'A-Team', roles: [developer]
      expect(members_page2).to have_user 'Peter Pan', roles: [manager, developer]
      expect(members_page2).not_to have_user 'Hannibal Smith'

      # Add hannibal to the group
      group_page.visit!
      group_page.add_user! 'Hannibal'
      expect(page).to have_text 'Successful update'

      members_page1.visit!
      expect(members_page1).to have_group 'A-Team', roles: [developer]
      expect(members_page1).to have_user 'Peter Pan', roles: [manager, developer]
      expect(members_page1).to have_user 'Hannibal Smith', roles: [developer]

      members_page2.visit!

      expect(members_page2).to have_group 'A-Team', roles: [developer]
      expect(members_page2).to have_user 'Peter Pan', roles: [manager, developer]
      expect(members_page2).to have_user 'Hannibal Smith', roles: [developer]

      group_member = project2.member_principals.find_by(user_id: group.id)
      expect(group_member.member_roles.count).to eq 1
      group_member_role = group_member.member_roles.first
      expect(group_member_role.role).to eq developer

      # Expect hannibal's role to be inherited by the group role
      hannibal_member = project2.members.find_by(user_id: hannibal.id)
      expect(hannibal_member.member_roles.count).to eq 1
      expect(hannibal_member.member_roles.first.inherited_from).to eq group_member_role.id
      expect(hannibal_member.member_roles.first.role).to eq developer

      # Remove the group from members page
      members_page2.remove_group! 'A-Team'
      expect(page).to have_text 'Removed A-Team from project.', wait: 10
      expect(members_page2).to have_user 'Peter Pan', roles: [manager]

      expect(members_page2).not_to have_group 'A-Team'
      expect(members_page2).not_to have_user 'Hannibal Smith'

      # Expect we can remove peter pan now
      members_page2.remove_user! 'Peter Pan'

      expect(page).to have_text 'Removed Peter Pan from project.', wait: 10
      expect(members_page2).not_to have_user 'Peter Pan'
      expect(members_page2).not_to have_group 'A-Team'
      expect(members_page2).not_to have_user 'Hannibal Smith'
    end
  end
end
