#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Quick-add menu", :js, :with_cuprite do
  let(:quick_add) { Components::QuickAddMenu.new }

  context "as a logged in user with add_project permission" do
    current_user { create(:user, global_permissions: %i[add_project]) }

    it "shows the add project option" do
      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project
      quick_add.expect_user_invite present: false
      quick_add.expect_no_work_package_types

      quick_add.click_link "Project"
      expect(page).to have_current_path new_project_path
    end

    context "with an existing project" do
      let(:project) { create(:project) }
      let(:field) { FormFields::SelectFormField.new :parent }

      current_user do
        create(:user,
               member_with_permissions: { project => %i[add_subprojects] })
      end

      it "moves to a form with parent_id set" do
        visit project_path(project)

        quick_add.expect_visible
        quick_add.toggle
        quick_add.expect_add_project

        quick_add.click_link "Project"
        expect(page).to have_current_path new_project_path(parent_id: project.id)

        field.expect_selected project.name
      end
    end
  end

  context "with current user as member with permission :manage_members in one project" do
    let!(:project) { create(:project) }
    let(:invite_modal) { Components::Users::InviteUserModal.new project:, role: nil, principal: nil }

    current_user do
      create(:user,
             member_with_permissions: { project => %i[manage_members] })
    end

    it "shows the user invite screen" do
      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project present: false
      quick_add.expect_no_work_package_types
      quick_add.expect_user_invite

      quick_add.click_link "Invite user"
      invite_modal.expect_open
    end
  end

  context "with a project with one of three work package types" do
    let!(:type_bug) { create(:type_bug) }
    let!(:other_type) { create(:type_task) }
    let!(:other_project_type) { create(:type) }
    let!(:add_role) { create(:project_role, permissions: %i[add_work_packages]) }
    let!(:read_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let!(:project_with_permission) do
      create(:project,
             types: [type_bug],
             members: { current_user => add_role })
    end
    let!(:other_project_with_permission) do
      create(:project,
             types: [other_project_type],
             members: { current_user => add_role })
    end
    let!(:project_without_permission) do
      create(:project,
             types: [other_type],
             members: { current_user => read_role })
    end

    current_user { create(:user) }

    it "shows only the project types within a project and only those types in projects the user can add work packages in" do
      visit project_path(project_with_permission)

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_add_project present: false
      quick_add.expect_user_invite present: false
      quick_add.expect_work_package_type type_bug.name
      quick_add.expect_work_package_type other_type.name, present: false
      quick_add.expect_work_package_type other_project_type.name, present: false
      quick_add.click_link type_bug.name

      expect(page)
        .to have_current_path new_project_work_packages_path(project_id: project_with_permission, type: type_bug.id)

      visit project_path(project_without_permission)

      quick_add.expect_invisible

      visit home_path

      quick_add.expect_visible
      quick_add.toggle
      quick_add.expect_work_package_type type_bug.name
      quick_add.expect_work_package_type other_type.name, present: false
      quick_add.expect_work_package_type other_project_type.name

      quick_add.click_link other_project_type.name
      expect(page).to have_current_path new_work_packages_path(type: other_project_type.id)
    end
  end

  context "as a logged in user with no permissions" do
    current_user { create(:user) }

    it "does not show the quick add menu on the home screen" do
      visit home_path
      quick_add.expect_invisible
    end
  end

  context "as an anonymous user", with_settings: { login_required: true } do
    current_user do
      create(:anonymous_role, permissions: %i[add_work_packages])
      create(:anonymous)
    end

    it "does not show the quick add menu on the home screen" do
      visit signin_path
      quick_add.expect_invisible
    end
  end
end
