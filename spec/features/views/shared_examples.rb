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

RSpec.shared_examples "module specific query view management" do
  describe "within a module" do
    let(:query_title) { Components::WorkPackages::QueryTitle.new }
    let(:query_menu) { Components::Submenu.new }
    let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
    let(:filters) { module_page.filters }

    it "allows to save, rename and delete a query" do
      # Change the query
      filters.open
      filters.add_filter_by "Subject", "contains", ["Test"]
      filters.expect_filter_count(initial_filter_count + 1)

      # Save it
      query_title.expect_changed
      settings_menu.open_and_save_query "My first query"
      query_title.expect_not_changed
      query_title.expect_title "My first query"
      query_menu.expect_item "My first query", selected: true

      # Change the filter again
      filters.add_filter_by "% Complete", "is", ["25"], "percentageDone"
      filters.expect_filter_count(initial_filter_count + 2)

      # Save as another query
      query_title.expect_changed
      settings_menu.open_and_save_query_as "My second query"
      query_title.expect_not_changed
      query_title.expect_title "My second query"
      query_menu.expect_item "My second query", selected: true
      query_menu.expect_item "My first query"

      # Rename a query
      settings_menu.open_and_choose "Rename view"
      expect(page).to have_focus_on(".editable-toolbar-title--input")
      page.driver.browser.switch_to.active_element.send_keys("My second query (renamed)")
      page.driver.browser.switch_to.active_element.send_keys(:return)
      module_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      query_title.expect_not_changed
      query_title.expect_title "My second query (renamed)"
      query_menu.expect_item "My second query (renamed)", selected: true
      query_menu.expect_item "My first query"

      # Delete a query
      settings_menu.open_and_choose "Delete"
      module_page.accept_alert_dialog!

      query_title.expect_title default_name
      query_menu.expect_no_item "My query planner (renamed)"
      query_menu.expect_item "My first query"
    end
  end
end
