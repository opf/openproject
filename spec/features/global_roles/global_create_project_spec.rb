# frozen_string_literal: true

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

RSpec.describe "Global role: Global Create project", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project) }

  let(:projects_page) { Pages::Projects::Index.new }

  describe "Create project is not a member permission" do
    # Given there is a role "Member"
    let!(:role) { create(:project_role, name: "Member") }

    # And I am already admin
    current_user { admin }

    # When I go to the edit page of the role "Member"
    # Then I should not see "Create project"
    it "does not show the global permission" do
      visit edit_role_path(role)
      expect(page).to have_css(".form--label-with-check-box", text: "Edit project")
      expect(page).to have_no_css(".form--label-with-check-box", text: "Create project")
    end
  end

  describe "Create project is a global permission" do
    # Given there is a global role "Global"
    let!(:role) { create(:global_role, name: "Global") }

    # And I am already admin
    current_user { admin }

    # When I go to the edit page of the role "Global"
    # Then I should see "Create project"

    it "does show the global permission" do
      visit edit_role_path(role)
      expect(page).to have_no_css(".form--label-with-check-box", text: "Edit project")
      expect(page).to have_css(".form--label-with-check-box", text: "Create project")
    end
  end

  describe "for a user with the global permission to add projects" do
    let!(:global_role) { create(:global_role, name: "Global", permissions: %i[add_project]) }
    let!(:member_role) { create(:project_role, name: "Member", permissions: %i[view_project]) }
    let!(:default_project_role) { create(:project_creator_role) }

    let!(:global_member) do
      create(:global_member,
             principal: user,
             roles: [global_role])
    end

    current_user { user }

    before do
      allow(Setting).to receive(:new_project_user_role_id).and_return(default_project_role.id.to_s)
    end

    it 'allows creating projects via the "+ Project" button' do
      projects_page.visit!
      projects_page.create_new_workspace :project

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Fill in project details
      fill_in "Name", with: "New project name"

      click_on "Complete"

      expect(page).to have_current_path "/projects/new-project-name"
    end
  end

  describe "for a user without permission to add projects" do
    current_user { user }

    it "does show the button for project creation" do
      projects_page.visit!
      projects_page.expect_no_project_create_button
    end
  end

  describe "projects menu" do
    let(:projects_menu) { Components::Projects::TopMenu.new }

    current_user { admin }

    it "does not show the button for project creation and list" do
      projects_page.visit!
      projects_menu.toggle!
      projects_menu.expect_no_project_create_button
      projects_menu.expect_no_project_list_button
    end
  end
end
