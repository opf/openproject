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

feature 'Quick-add menu', js: true, selenium: true do
  let(:quick_add) { ::Components::QuickAddMenu.new }

  context 'as a logged in user with add_project permission' do
    current_user { FactoryBot.create :user, global_permission: %i[add_project] }

    it 'shows the add project option' do
      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project
      quick_add.expect_user_invite present: false
      quick_add.expect_no_work_package_types

      quick_add.click_link 'Project'
      expect(page).to have_current_path new_project_path
    end

    context 'with an existing project' do
      let(:project) { FactoryBot.create :project }
      current_user do
        FactoryBot.create :user,
                          member_in_project: project,
                          member_with_permissions: %i[add_project view_project add_subprojects]
      end

      let(:field) { ::FormFields::SelectFormField.new :parent }

      it 'moves to a form with parent_id set' do
        visit project_path(project)

        quick_add.expect_visible
        quick_add.toggle
        quick_add.expect_add_project

        quick_add.click_link 'Project'
        expect(page).to have_current_path new_project_path(parent_id: project.id)

        field.expect_selected project.name
      end
    end
  end

  context 'with current user as member with permission :manage_members in one project' do
    let!(:project) { FactoryBot.create :project }
    let(:invite_modal) { ::Components::Users::InviteUserModal.new project: project, role: nil, principal: nil }

    current_user do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_with_permissions: %i[manage_members]
    end

    it 'shows the user invite screen' do
      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project present: false
      quick_add.expect_no_work_package_types
      quick_add.expect_user_invite

      quick_add.click_link 'Invite user'
      invite_modal.expect_open
    end
  end

  context 'with a project with one of two work package types' do
    let!(:type_bug) { FactoryBot.create :type_bug }
    let!(:other_type) { FactoryBot.create :type_task }
    let!(:project) { FactoryBot.create :project, types: [type_bug] }

    current_user do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_with_permissions: %i[add_work_packages]
    end

    it 'shows both types outside and the one within' do
      visit project_path(project)

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project present: false
      quick_add.expect_user_invite present: false
      quick_add.expect_work_package_type type_bug.name
      quick_add.expect_work_package_type other_type.name, present: false
      quick_add.click_link type_bug.name

      expect(page)
        .to have_current_path new_project_work_packages_path(project_id: project, type: type_bug.id)

      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_work_package_type type_bug.name
      quick_add.expect_work_package_type other_type.name

      quick_add.click_link other_type.name
      expect(page).to have_current_path new_work_packages_path(type: other_type.id)
    end
  end

  context 'as a logged in user with no permissions' do
    current_user { FactoryBot.create :user }

    it 'does not show the quick add menu on the home screen' do
      visit home_path
      quick_add.expect_invisible
    end
  end

  context 'as an anonymous user', with_settings: { login_required: true } do
    current_user do
      FactoryBot.create(:anonymous_role, permissions: %i[add_work_packages])
      FactoryBot.create :anonymous
    end

    it 'does not show the quick add menu on the home screen' do
      visit signin_path
      quick_add.expect_invisible
    end
  end
end
