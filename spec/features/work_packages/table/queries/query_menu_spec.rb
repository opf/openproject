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

RSpec.describe "Query menu item", :js do
  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:query_title) { Components::WorkPackages::QueryTitle.new }

  current_user { create(:admin) }

  context "when visiting the global work packages page" do
    let(:wp_table) { Pages::WorkPackagesTable.new }
    let(:project) { nil }

    let!(:global_public_view) do
      create(:view,
             query: create(:query, project: nil, public: true, name: "Global public"))
    end

    let!(:global_my_view) do
      create(:view,
             query: create(:query, project: nil, public: false, user: current_user, name: "Global my view"))
    end

    let!(:global_other_view) do
      create(:view,
             query: create(:query, project: nil, public: false, user: create(:user), name: "Other user query"))
    end

    let!(:project_view) do
      create(:view,
             query: create(:query, project: create(:project), name: "Project query"))
    end

    it "shows the query menu with queries stored for the global page" do
      wp_table.visit!
      expect(page).to have_test_selector("op-submenu--body")
      expect(page).to have_css(".op-submenu--item-action", wait: 20, minimum: 1)

      within ".op-submenu" do
        expect(page)
          .to have_content(global_my_view.query.name, wait: 10)
        expect(page)
          .to have_content(global_public_view.query.name, wait: 10)
        expect(page)
          .to have_no_content(global_other_view.query.name)
        expect(page)
          .to have_no_content(project_view.query.name)
      end
    end
  end

  context "when filtering by version in project" do
    let(:version) { create(:version, project:) }
    let(:work_package_with_version) { create(:work_package, project:, version:) }
    let(:work_package_without_version) { create(:work_package, project:) }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it "allows to save query as name with sharing options (Regression #27915)" do
      # Publish query
      wp_table.click_setting_item "Save as"

      fill_in "save-query-name", with: "Some query name"
      find_by_id("show-in-menu").set true
      find_by_id("show-public").set true

      find(".button", text: "Save").click

      expect(page).to have_css(".op-submenu--item-action", text: "Some query name", wait: 20)

      last_query = Query.last
      expect(last_query.public).to be_truthy
    end

    it "only saves a single query when saving through the title input (Regression #31095)" do
      filters.open
      filters.remove_filter("status")

      filters.expect_filter_count 0
      query_title.expect_changed

      query_title.input_field.click
      query_title.rename "My special query!123"

      query_title.expect_title "My special query!123"
      expect(page).to have_css(".op-submenu--item-action", text: "My special query!123", wait: 20, count: 1)
    end

    it "allows filtering, saving, retrieving and altering the saved filter (Regression #25372)" do
      filters.open
      filters.add_filter_by("Version", "is (OR)", version.name)

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      wp_table.save_as("Some query name")

      filters.remove_filter "version"
      filters.expect_filter_count 1

      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      last_query = Query.last

      expect(URI.parse(page.current_url).query).to include("query_id=#{last_query.id}&query_props=")

      # Publish query
      wp_table.click_setting_item I18n.t("js.label_visibility_settings")
      find_by_id("show-in-menu").set true
      find(".button", text: "Save").click

      wp_table.visit!
      loading_indicator_saveguard

      filters.open
      filters.remove_filter "status"
      filters.expect_filter_count 0

      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      # Locate query
      query_item = page.find(".op-submenu--item-action", text: "Some query name")
      query_item.click

      # Overrides the query_props
      retry_block do
        # Run in retry block because page.current_url is not synchronized
        raise "query_props should not be in URL path" if page.current_url.include?("query_props")
      end

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      filters.expect_filter_count 2
      filters.open
      filters.expect_filter_by("Version", "is (OR)", version.name)

      # Removing the filter and returning to query restores it
      filters.remove_filter "version"
      filters.expect_filter_count 1
      expect(page.current_url).to include("query_props")

      query_item = page.find(".op-submenu--item-action", text: "Some query name")
      query_item.click

      retry_block do
        # Run in retry block because page.current_url is not synchronized
        raise "query_props should not be in URL path" if page.current_url.include?("query_props")
      end

      filters.expect_filter_count 2
      filters.open
      filters.expect_filter_by("Version", "is (OR)", version.name)
    end
  end
end
