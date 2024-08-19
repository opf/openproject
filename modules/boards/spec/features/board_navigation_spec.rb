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
require_relative "support/board_index_page"
require_relative "support/board_page"

RSpec.describe "Work Package boards spec", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  # The identifier is important to test https://community.openproject.com/wp/29754
  let(:project) { create(:project, identifier: "boards", enabled_module_names: %i[work_package_tracking board_view]) }
  let(:permissions) { %i[show_board_views manage_board_views add_work_packages view_work_packages manage_public_queries] }
  let(:role) { create(:project_role, permissions:) }
  let(:admin) { create(:admin) }
  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:default_status) }
  let(:board_index) { Pages::BoardIndex.new(project) }
  let!(:board_view) { create(:board_grid_with_query, name: "My board", project:) }
  let(:project_html_title) { Components::HtmlTitle.new project }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

  before do
    project
    login_as(user)
    project
    login_as(admin)
  end

  it "navigates from boards to the WP full view and back" do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Task 1"
    board_page.expect_toast message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq "Task 1"
    # Double click leads to the full view
    click_target = page.find_test_selector("op-wp-single-card--content-type")
    page.driver.browser.action.double_click(click_target.native).perform

    expect(page).to have_current_path project_work_package_path(project, wp.id, "activity")

    # Click back goes back to the board
    find(".work-packages-back-button").click
    expect(page).to have_current_path project_work_package_board_path(project, board_view)

    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.expect_subject

    expect(page).to have_current_path /details\/#{wp.id}\/overview/
    card.expect_selected

    # Add a second card, focus on that
    board_page.add_card "List 1", "Foobar"
    board_page.expect_toast message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq "Foobar"
    card = board_page.card_for(wp)

    # Click on the card
    card.card_element.click
    expect(page).to have_current_path /details\/#{wp.id}\/overview/
  end

  it "navigates correctly the path from overview page to the boards page",
     # The polling interval is only lowered as the sidemenu relies on Angular's change
     # detection to be updated. This is a bug.
     # In reality, it does not really matter as the user will always move the mouse or do
     # a similar action.
     with_settings: { notifications_polling_interval: 1_000 } do
    visit project_path(project)

    page.find_test_selector("main-menu-toggler--boards", wait: 10).click

    subitem = page.find_test_selector("op-submenu--item-action", text: "My board", wait: 10)
    # Ends with boards due to lazy route
    expect(subitem[:href]).to end_with project_work_package_board_path(project, board_view.id)

    subitem.click

    board_page = Pages::Board.new board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Task 1"
  end

  it "navigates from boards to the WP details view then go to full view then go back (see #33747)" do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Task 1"
    board_page.expect_toast message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq "Task 1"
    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.ensure_page_loaded
    split_view.expect_subject
    split_view.switch_to_tab tab: "Relations"

    # Go to full view of WP
    full_view = split_view.switch_to_fullscreen
    full_view.expect_tab "Relations"

    # Go back to details view with selected tab
    full_view.go_back
    split_view.expect_subject

    expect(page).to have_current_path /details\/#{wp.id}\/relations/
    split_view.expect_tab "Relations"
  end

  it "navigates to the details view and reloads (see #49678)" do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Task 1"
    board_page.expect_toast message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq "Task 1"
    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.ensure_page_loaded
    split_view.expect_subject

    page.driver.refresh

    split_view.ensure_page_loaded
    split_view.expect_subject
  end

  it "navigates to boards after deleting WP(see #33756)" do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Task 1"
    board_page.expect_toast message: I18n.t(:notice_successful_create)
    wp = WorkPackage.last
    expect(wp.subject).to eq "Task 1"

    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.expect_subject

    # Go to full view of WP
    split_view.switch_to_fullscreen
    find_by_id("action-show-more-dropdown-menu").click
    click_link(I18n.t("js.button_delete"))

    # Delete the WP
    destroy_modal.expect_listed(wp)
    destroy_modal.confirm_deletion

    board_page.expect_empty
    board_page.expect_path
  end
end
