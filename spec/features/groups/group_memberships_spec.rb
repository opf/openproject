#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'group memberships through groups page', type: :feature do
  let!(:project) { FactoryGirl.create :project, name: 'Project 1', identifier: 'project1' }

  let(:admin)     { FactoryGirl.create :admin }
  let!(:peter)    { FactoryGirl.create :user, firstname: 'Peter', lastname: 'Pan' }
  let!(:hannibal) { FactoryGirl.create :user, firstname: 'Hannibal', lastname: 'Smith' }
  let(:group)     { FactoryGirl.create :group, lastname: 'A-Team' }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }
  let(:group_page)   { Pages::Groups.new.group(group.id) }

  before do
    allow(User).to receive(:current).and_return admin

    group.add_member! peter
  end

  scenario 'adding a user to a group adds the user to the project as well', js: true do
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
      group.add_member! hannibal
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

    scenario 'removing the group from a project', js: true do
      group_page.visit!
      group_page.open_projects_tab!
      expect(group_page).to have_project 'Project 1'

      group_page.remove_from_project! 'Project 1'
      expect(page).to have_text 'Successful deletion'
      expect(page).to have_text ' There are currently no projects part of this group.'
    end
  end
end
