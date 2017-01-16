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

feature 'members pagination', type: :feature, js: true do
  let!(:project) { FactoryGirl.create :project, name: 'Project 1', identifier: 'project1' }

  let(:admin)  { FactoryGirl.create :admin }
  let!(:peter) { FactoryGirl.create :user, firstname: 'Peter', lastname: 'Pan' }
  let!(:bob)   { FactoryGirl.create :user, firstname: 'Bob', lastname: 'Bobbit' }
  let!(:alice) { FactoryGirl.create :user, firstname: 'Alice', lastname: 'Alison' }

  let!(:manager)   { FactoryGirl.create :role, name: 'Manager' }
  let!(:developer) { FactoryGirl.create :role, name: 'Developer' }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin

    project.add_member! bob, [manager]
    project.add_member! alice, [developer]
  end

  scenario 'paginating after adding a member' do
    members_page.set_items_per_page! 2

    members_page.visit!
    members_page.add_user! 'Peter Pan', as: 'Manager'

    members_page.go_to_page! 2
    expect(members_page).to have_user 'Alice Alison' # members are sorted by last name desc
  end

  scenario 'Paginating after removing a member' do
    project.add_member! peter, [manager]
    members_page.set_items_per_page! 1

    members_page.visit!
    members_page.remove_user! 'Peter Pan'
    expect(members_page).to have_user 'Bob Bobbit'

    members_page.go_to_page! 2
    expect(members_page).to have_user 'Alice Alison'
  end

  scenario 'Paginating after updating a member' do
    members_page.set_items_per_page! 1

    members_page.visit!
    members_page.edit_user! 'Bob Bobbit', add_roles: ['Developer']
    expect(page).to have_text 'Successful update'
    expect(members_page).to have_user 'Bob Bobbit', roles: ['Developer', 'Manager']

    members_page.go_to_page! 2
    expect(members_page).to have_user 'Alice Alison'
  end
end
