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

require_relative "../../support/pages/my/page"

RSpec.describe "Arbitrary WorkPackage query table widget on my page", :js do
  let!(:type) { create(:type) }
  let!(:other_type) { create(:type) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, types: [type]) }
  let!(:other_project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:type_work_package) do
    create(:work_package,
           project:,
           type:,
           author: user,
           responsible: user)
  end
  let!(:other_type_work_package) do
    create(:work_package,
           project:,
           type: other_type,
           author: user,
           responsible: user)
  end

  let(:permissions) { %i[view_work_packages add_work_packages save_queries] }

  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { Components::WorkPackages::TableConfiguration::Filters.new }
  let(:columns) { Components::WorkPackages::Columns.new }

  before do
    login_as user

    my_page.visit!
  end

  context "with the permission to save queries" do
    it "can add the widget and see the work packages of the filtered for types" do
      # This one always exists by default.
      # Using it here as a safeguard to govern speed.
      created_by_me_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(2)")
      expect(created_by_me_area.area)
        .to have_css(".subject", text: type_work_package.subject)

      my_page.add_widget(1, 2, :column, "Work packages table")

      # Actually there are two success messages displayed currently. One for the grid getting updated and one
      # for the query assigned to the new widget being created. A user will not notice it but the automated
      # browser can get confused. Therefore we wait.
      sleep(2)

      my_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      filter_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(3)")
      filter_area.expect_to_span(1, 2, 2, 3)

      # At the beginning, the default query is displayed
      expect(filter_area.area)
        .to have_css(".subject", text: type_work_package.subject)

      expect(filter_area.area)
        .to have_css(".subject", text: other_type_work_package.subject)

      # User has the ability to modify the query

      filter_area.configure_wp_table
      modal.switch_to("Filters")
      filters.expect_filter_count(2)
      filters.add_filter_by("Type", "is (OR)", type.name)
      modal.save

      filter_area.configure_wp_table
      modal.switch_to("Columns")
      columns.assume_opened
      columns.remove "Subject"

      expect(filter_area.area)
        .to have_css(".id", text: type_work_package.id)

      # as the Subject column is disabled
      expect(filter_area.area)
        .to have_no_css(".subject", text: type_work_package.subject)

      # As other_type is filtered out
      expect(filter_area.area)
        .to have_no_css(".id", text: other_type_work_package.id)

      scroll_to_element(filter_area.area)
      within filter_area.area do
        input = find(".editable-toolbar-title--input")
        input.set("My WP Filter")
        input.native.send_keys(:return)
      end

      my_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

      sleep(1)

      # The whole of the configuration survives a reload
      # as it is persisted in the grid

      visit root_path
      my_page.visit!

      filter_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(3)")
      expect(filter_area.area)
        .to have_css(".id", text: type_work_package.id)

      # as the Subject column is disabled
      expect(filter_area.area)
        .to have_no_css(".subject", text: type_work_package.subject)

      # As other_type is filtered out
      expect(filter_area.area)
        .to have_no_css(".id", text: other_type_work_package.id)

      within filter_area.area do
        expect(page).to have_field("editable-toolbar-title", with: "My WP Filter", wait: 10)
      end
    end
  end

  context "without the permission to save queries" do
    let(:permissions) { %i[view_work_packages add_work_packages] }

    it "cannot add the widget" do
      my_page.expect_unable_to_add_widget(1, 1, :within, "Work packages table")
    end
  end
end
