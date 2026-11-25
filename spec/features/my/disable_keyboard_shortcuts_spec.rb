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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "My account disable keyboard shortcuts setting", :js do
  let(:user) { create(:user) }
  let(:global_search) { Components::GlobalSearch.new }

  before do
    login_as(user)
    visit my_account_path
  end

  it "can disable the keyboard short cuts" do
    click_on "Interface"

    # Per default, the keyboard short cuts are enabled
    expect(page).to have_unchecked_field("Disable keyboard shortcuts", visible: :visible)
    page.driver.send_keys("s")
    global_search.expect_open

    # Check the checkbox
    page.check("Disable keyboard shortcuts")
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)

    # Save
    click_button accessible_name: "Update look and feel"
    wait_for_network_idle
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)

    # Directly try to trigger the keyboard short cut again (which should not work any more)
    page.driver.send_keys("s")
    global_search.expect_closed

    # After a hard reload, the setting is still remembered and turned off
    page.refresh
    wait_for_network_idle
    expect(page).to have_checked_field("Disable keyboard shortcuts", visible: :visible)
    page.driver.send_keys("s")
    global_search.expect_closed
  end

  describe "navigating to another page after disabling" do
    let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:work_package) { create(:work_package, project:) }
    let(:split_view) { Pages::SplitWorkPackage.new(work_package, project) }
    let(:user) { create(:admin) }

    before do
      user.pref.update!(disable_keyboard_shortcuts: true)
      work_package
    end

    it "fires no hotkeys on pages reached by a link click" do
      visit project_path(project)
      click_on "Work packages"
      wp_table.expect_work_package_listed(work_package)

      page.send_keys("m")
      wait_for_network_idle
      expect(page).to have_no_menu

      page.send_keys("d", "w", "p")
      wait_for_network_idle
      split_view.expect_closed
      expect(page).to have_current_path(project_work_packages_path(project), ignore_query: true)

      page.send_keys("g", "m")
      wait_for_network_idle
      expect(page).to have_current_path(project_work_packages_path(project), ignore_query: true)
    end

    it "gives native key 7 to the details More in the split view" do
      split_view.visit!
      split_view.expect_open
      expect(page).to have_button(accessible_name: "More actions")
      expect(page).to have_button(accessible_name: "More", exact: true)

      expect(page).to have_element(accesskey: "7", count: 1, visible: :all)
      expect(page).to have_element(:button, accesskey: "7", accessible_name: "More", exact: true)
    end
  end
end
