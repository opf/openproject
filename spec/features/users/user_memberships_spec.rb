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

feature 'user memberships through user page', type: :feature, js: true do
  let!(:project) { FactoryGirl.create :project, name: 'Project 1', identifier: 'project1' }
  let(:admin) { FactoryGirl.create :admin, firstname: 'Foobar', lastname: 'Blabla' }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let(:user_page)   { Pages::Admin::User.new(admin.id) }

  before do
    login_as(admin)

    user_page.visit!
    user_page.open_projects_tab!
  end

  scenario 'handles role modification flow' do
    user_page.add_to_project! project.name, as: 'Manager'

    member = admin.memberships.where(project_id: project.id).first
    user_page.edit_roles!(member, %w(Manager Developer))

    # Modify roles
    user_page.expect_project(project.name)
    user_page.expect_roles(project.name, %w(Manager Developer))

    # Remove all roles
    user_page.expect_project(project.name)
    user_page.edit_roles!(member, %w())

    expect(page).to have_selector('#errorExplanation', 'Please choose at least one role.')
  end

  context 'when user has an inherited role' do
    let(:group)     { FactoryGirl.create :group, lastname: 'A-Team' }
    let(:group_page)   { Pages::Groups.new.group(group.id) }

    before do
      group.add_member! admin
    end

    scenario 'it can remove all other roles' do
      user_page.expect_no_membership(project.name)

      group_page.visit!
      group_page.add_to_project! project.name, as: 'Manager'
      expect(page).to have_text 'Successful update'

      user_page.visit!
      user_page.open_projects_tab!

      # Expect inherited membership
      user_page.expect_project(project.name)
      user_page.expect_roles(project.name, %w(Manager))

      # Remove all roles
      member = admin.memberships.where(project_id: project.id).first
      user_page.edit_roles!(member, %w())

      # Keeps inherited role
      user_page.expect_project(project.name)
      user_page.expect_roles(project.name, %w(Manager))

      # Extend roles
      user_page.edit_roles!(member, %w(Developer))
      user_page.expect_project(project.name)
      user_page.expect_roles(project.name, %w(Manager Developer))
    end
  end
end
