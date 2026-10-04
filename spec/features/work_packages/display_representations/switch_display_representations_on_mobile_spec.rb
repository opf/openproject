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

RSpec.describe "Switching work package view on mobile", :js, :selenium do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:cards) { Pages::WorkPackageCards.new(project) }

  let(:wp1) do
    create(:work_package,
           project:)
  end
  let(:wp2) do
    create(:work_package,
           project:)
  end

  before do
    wp1
    wp2

    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed wp1, wp2
  end

  context "in mobile card view" do
    include_context "with mobile screen size"

    it "can switch the representation automatically on mobile after a refresh" do
      # It shows the elements as cards
      cards.expect_work_package_listed wp1, wp2

      # A single click leads to the full view
      cards.select_work_package(wp1)
      expect(page).to have_heading(wp1.subject, level: 2, exact_text: true)
      page.go_back
      # The query is however unchanged
      expect(page).to have_no_css(".editable-toolbar-title--save")
      url = URI.parse(page.current_url).query
      expect(url).not_to match(/query_props=.+/)

      # Since the query is unchanged, the WPs will be displayed as list on larger screens again
      page.driver.browser.manage.window.resize_to(700, 1080)
      page.driver.browser.navigate.refresh
      wp_table.expect_work_package_listed wp1, wp2
      wp_table.expect_work_package_order wp1, wp2
    end
  end
end
