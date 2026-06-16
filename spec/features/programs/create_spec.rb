# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Programs",
               "creation",
               :js do
  shared_let(:user_with_permissions) do
    create(:user,
           global_permissions: :add_programs)
  end
  # Role granted to creator on program creation to be able to access the program.
  shared_let(:default_project_role) { create(:project_creator_role) }
  shared_let(:add_subproject_role) { create(:project_role, permissions: %i[add_subprojects]) }

  before do
    allow(Setting).to receive(:new_project_user_role_id).and_return(default_project_role.id.to_s)
  end

  let!(:root_portfolio) do
    create(:portfolio, name: "Root portfolio", members: { user_with_permissions => add_subproject_role })
  end
  let!(:other_portfolio) do
    create(:portfolio, name: "Other portfolio")
  end

  let(:projects_page) { Pages::Projects::Index.new }
  let(:parent_field) { FormFields::SelectFormField.new :parent }

  current_user { user_with_permissions }

  context "with enterprise feature enabled", with_ee: :portfolio_management do
    it "can create a program" do
      projects_page.visit!
      projects_page.create_new_workspace :program

      expect(page).to have_heading "New program"

      # Step 1: Select workspace type (blank program)
      click_on "Continue"

      # Step 2: Fill in project details
      fill_in "Name", with: "Foo bar"

      expect(page).to have_combo_box "Subproject of"
      parent_field.expect_no_option "Other portfolio"
      parent_field.select_option "Root portfolio"

      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content "Foo bar"

      program = Project.last
      expect(program.workspace_type).to eq "program"
      expect(program.identifier).to eq "foo-bar"
      expect(program.parent).to eq root_portfolio
    end

    context "without the necessary permissions to create programs" do
      current_user { create(:user) }

      it "cannot create the program" do
        visit new_program_path

        expect(page).to have_content "[Error 403] You are not authorized to access this page."
      end
    end
  end

  context "without enterprise feature enabled", with_ee: [] do
    it "shows enterprise banner instead of the form" do
      projects_page.visit!
      projects_page.create_new_workspace :program

      expect(page).to have_heading "New program"

      expect(page).to have_no_button "Continue"

      expect(page).to have_enterprise_banner(:premium, class: "op-enterprise-banner_large")
    end
  end
end
