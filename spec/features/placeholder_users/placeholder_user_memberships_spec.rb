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

feature 'placeholder user memberships through placeholder user page', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }
  let!(:project2) { FactoryBot.create :project, name: 'Project 2', identifier: 'project2' }
  let(:admin) { FactoryBot.create :admin }
  let(:placeholder_user) { FactoryBot.create :placeholder_user, name: 'UX Designer' }

  let!(:manager)   { FactoryBot.create :role, name: 'Manager' }
  let!(:developer) { FactoryBot.create :role, name: 'Developer' }

  let(:placeholder_user_page) { Pages::Admin::IndividualPrincipals::Edit.new(placeholder_user) }

  before do
    login_as(admin)

    placeholder_user_page.visit!
    placeholder_user_page.open_projects_tab!
  end

  scenario 'handles role modification flow' do
    placeholder_user_page.add_to_project! project.name, as: 'Manager'

    member = placeholder_user.memberships.where(project_id: project.id).first
    placeholder_user_page.edit_roles!(member, %w(Manager Developer))

    # Modify roles
    placeholder_user_page.expect_project(project.name)
    placeholder_user_page.expect_roles(project.name, %w(Manager Developer))

    placeholder_user_page.expect_no_membership(project2.name)

    # Remove all roles
    placeholder_user_page.expect_project(project.name)
    placeholder_user_page.edit_roles!(member, %w())

    expect(page).to have_selector('.flash.error', text: 'Roles need to be assigned.')

    # Remove the user from the project
    placeholder_user_page.remove_from_project!(project.name)
    placeholder_user_page.expect_no_membership(project.name)

    # Re-add the user
    placeholder_user_page.add_to_project! project.name, as: %w(Manager Developer)

    placeholder_user_page.expect_project(project.name)
    placeholder_user_page.expect_roles(project.name, %w(Manager Developer))
  end
end
