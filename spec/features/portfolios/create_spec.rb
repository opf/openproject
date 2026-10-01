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

RSpec.describe "Portfolios",
               "creation",
               :js do
  shared_let(:user_with_permissions) do
    create(:user,
           global_permissions: :add_portfolios)
  end
  # Role granted to creator on portfolio creation to be able to access the portfolio.
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
    it "can create a portfolio" do
      projects_page.visit!
      projects_page.create_new_workspace :portfolio

      expect(page).to have_heading "New portfolio"

      # Step 1: Select workspace type (blank portfolio)
      click_on "Continue"

      # Step 2: Fill in project details
      fill_in "Name", with: "Foo bar"

      # No parent field since portfolios are always root elements
      expect(page)
        .not_to have_combo_box "Subproject of"

      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content "Foo bar"

      portfolio = Project.last
      expect(portfolio.workspace_type).to eq "portfolio"
      expect(portfolio.identifier).to eq "foo-bar"
      expect(portfolio.parent).to be_nil
    end

    it "redirects to portfolios#index when users cancels" do
      visit new_portfolio_path

      expect(page).to have_heading "New portfolio"

      click_on "Cancel"
      expect(page).to have_current_path portfolios_path
    end

    context "without the necessary permissions to create portfolios" do
      current_user { create(:user) }

      it "cannot create the portfolio" do
        visit new_portfolio_path

        expect(page).to have_content "[Error 403] You are not authorized to access this page."
      end
    end
  end

  context "without enterprise feature enabled", with_ee: [] do
    it "shows enterprise banner instead of the form" do
      projects_page.visit!
      projects_page.create_new_workspace :portfolio

      expect(page).to have_heading "New portfolio"

      expect(page).to have_no_button "Continue"

      expect(page).to have_enterprise_banner(:premium, class: "op-enterprise-banner_large")
    end
  end
end
