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

RSpec.describe "Navigate to overview", :js do
  let(:project) { create(:project) }
  let(:permissions) { [] }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  let(:query_menu) { Components::Submenu.new }

  before do
    login_as user
  end

  it "can visit the overview page" do
    visit project_path(project)

    within "#menu-sidebar" do
      click_link "Overview"
    end

    within "#content" do
      expect(page)
        .to have_content("Overview")
    end
  end

  context "as user with permissions" do
    let(:project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
    let(:user) { create(:admin) }
    let(:query) do
      create(:query_with_view_work_packages_table,
             project:,
             user:,
             name: "My important Query")
    end

    before do
      query
      login_as user
    end

    it "can navigate to other modules (regression #55024)" do
      visit project_overview_path(project.id)

      # Expect page to be loaded
      within "#content" do
        expect(page).to have_content("Overview")
      end

      # Navigate to the WP module
      page.find_test_selector("main-menu-toggler--work_packages").click

      # Click on a saved query
      query_menu.click_item "My important Query"

      loading_indicator_saveguard

      within "#content" do
        # Expect the query content to be shown
        expect(page).to have_field("editable-toolbar-title", with: query.name)

        # Expect no page header of the Overview to be shown any more
        expect(page).to have_no_content("Overview")
      end

      # Navigate back to the Overview page
      page.execute_script("window.history.back()")

      # Expect page to be loaded
      within "#content" do
        expect(page).to have_content("Overview")
      end
    end
  end
end
