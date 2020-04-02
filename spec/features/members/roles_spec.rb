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

feature 'members pagination', type: :feature, js: true do
  using_shared_fixtures :admin
  let!(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }

  let!(:bob)   { FactoryBot.create :user, firstname: 'Bob', lastname: 'Bobbit' }
  let!(:alice) { FactoryBot.create :user, firstname: 'Alice', lastname: 'Alison' }

  let!(:alpha) { FactoryBot.create :role, name: 'alpha' }
  let!(:beta)  { FactoryBot.create :role, name: 'beta' }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin

    project.add_member! alice, [beta]
    project.add_member! bob, [alpha]

    members_page.visit!
  end

  scenario 'Adding a Role to Alice' do
    members_page.edit_user! 'Alice Alison', add_roles: ['alpha']

    expect(members_page).to have_user('Alice Alison', roles: ['alpha', 'beta'])
  end

  scenario 'Adding a role while taking another role away from Alice' do
    members_page.edit_user! 'Alice Alison', add_roles: ['alpha'], remove_roles: ['beta']

    expect(members_page).to have_user('Alice Alison', roles: 'alpha')
    expect(members_page).not_to have_roles('Alice Alison', ['beta'])
  end

  scenario "Removing Bob's last role results in an error" do
    members_page.edit_user! 'Bob Bobbit', remove_roles: ['alpha']

    expect(page).to have_text 'Roles need to be assigned.'
    expect(members_page).to have_user('Bob Bobbit', roles: ['alpha'])
  end
end
