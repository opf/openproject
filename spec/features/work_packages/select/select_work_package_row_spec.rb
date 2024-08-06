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

RSpec.describe "Select work package row", :js, :selenium do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package_1) { create(:work_package, project:) }
  let(:work_package_2) { create(:work_package, project:) }
  let(:work_package_3) { create(:work_package, project:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  include_context "work package table helpers"

  before do
    login_as(user)

    work_package_1
    work_package_2
    work_package_3

    wp_table.visit!
    wp_table.expect_work_package_listed(work_package_1)
    wp_table.expect_work_package_listed(work_package_2)
    wp_table.expect_work_package_listed(work_package_3)
  end

  def select_work_package_row(number, mouse_button_behavior = :left)
    element = find(".work-package-table--container tr:nth-of-type(#{number}) .wp-table--cell-td.id")
    loading_indicator_saveguard
    case mouse_button_behavior
    when :right
      element.right_click
    else
      element.click
    end
  end

  def select_work_package_row_with_shift(number)
    element = find(".work-package-table--container tr:nth-of-type(#{number}) .wp-table--cell-td.id")
    loading_indicator_saveguard

    page.driver.browser.action.key_down(:shift)
        .click(element.native)
        .key_up(:shift)
        .perform
  end

  def select_work_package_row_with_ctrl(number)
    element = find(".work-package-table--container tr:nth-of-type(#{number}) .wp-table--cell-td.id")
    loading_indicator_saveguard

    page.driver.browser.action.key_down(:meta)
        .click(element.native)
        .key_up(:meta)
        .perform
  end

  def expect_row_checked(*indices)
    indices.each do |i|
      check_row_selection_state(i, true)
    end
  end

  def expect_row_unchecked(*indices)
    indices.each do |i|
      check_row_selection_state(i, false)
    end
  end

  def check_row_selection_state(row_index, state = true)
    selector = ".work-package-table--container tr:nth-of-type(#{row_index}).issue"
    checked_selector = ".work-package-table--container tr:nth-of-type(#{row_index}).issue.-checked"

    expect(page).to have_selector(selector)
    expect(page).to (state ? have_selector(checked_selector) : have_no_selector(checked_selector))
  end

  def check_all
    find("body").send_keys [:control, "a"]
    expect_row_checked(1, 2, 3)
    expect(page).to have_no_css "#work-package-context-menu"
  end

  def uncheck_all
    find("body").send_keys [:control, "d"]
    expect_row_unchecked(1, 2, 3)
    expect(page).to have_no_css "#work-package-context-menu"
  end

  it "handles selection flows" do
    ###
    # Keyboard shortcuts
    ###
    check_all
    uncheck_all

    ###
    # SINGLE selections
    ###
    select_work_package_row(1, :left)
    expect_row_checked(1)

    # Select different row
    select_work_package_row(2, :left)
    expect_row_unchecked(1)
    expect_row_checked(2)

    # select different row with right click
    select_work_package_row(3, :right)
    expect_row_unchecked(1, 2)
    expect_row_checked(3)

    ###
    # RANGE subselection
    ###
    uncheck_all
    select_work_package_row_with_shift(1)
    expect_row_checked(1)

    select_work_package_row_with_shift(2)
    expect_row_checked(1, 2)
    expect_row_unchecked(3)

    ###
    # RANGE select all
    ###
    uncheck_all
    select_work_package_row_with_shift(1)
    expect_row_checked(1)

    select_work_package_row_with_shift(3)
    expect_row_checked(1, 2, 3)

    # Unselect the last row
    select_work_package_row_with_shift(2)
    expect_row_checked(1, 2)
    expect_row_unchecked(3)

    ###
    # SWAPPING
    ###
    uncheck_all
    select_work_package_row(2)
    expect_row_checked(2)

    # Select predecessor
    select_work_package_row_with_shift(1)
    expect_row_checked(1, 2)
    expect_row_unchecked(3)

    # Select successor
    select_work_package_row_with_shift(3)
    expect_row_unchecked(1)
    expect_row_checked(2, 3)

    ###
    # CTRL selections
    ###
    uncheck_all
    select_work_package_row_with_ctrl(1)
    expect_row_checked(1)

    # Select last row
    select_work_package_row_with_ctrl(3)
    expect_row_checked(1, 3)
    expect_row_unchecked(2)

    # Right click does not lose selection
    select_work_package_row(3, :right)
    expect_row_checked(1, 3)
    expect_row_unchecked(2)
  end

  describe "opening work package full screen view" do
    before do
      wp_table.open_full_screen_by_doubleclick(work_package_1)
    end

    it do
      expect(page).to have_css(".work-packages--details--subject",
                               text: work_package_1.subject)
    end
  end

  describe "opening last selected work package" do
    before do
      select_work_package_row(2)
      expect_row_checked(2)
    end

    it do
      find_by_id("work-packages-details-view-button").click
      split_wp = Pages::SplitWorkPackage.new(work_package_2)
      split_wp.expect_attributes Subject: work_package_2.subject

      find_by_id("work-packages-details-view-button").click
      expect(page).to have_no_css(".work-packages--details")
    end
  end
end
