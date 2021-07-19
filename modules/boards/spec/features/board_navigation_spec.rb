#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative './support/board_index_page'
require_relative './support/board_page'

describe 'Work Package boards spec', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  # The identifier is important to test https://community.openproject.com/wp/29754
  let(:project) { FactoryBot.create(:project, identifier: 'boards', enabled_module_names: %i[work_package_tracking board_view]) }
  let(:permissions) { %i[show_board_views manage_board_views add_work_packages view_work_packages manage_public_queries] }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:admin) { FactoryBot.create :admin }
  let!(:priority) { FactoryBot.create :default_priority }
  let!(:status) { FactoryBot.create :default_status }
  let(:board_index) { Pages::BoardIndex.new(project) }
  let!(:board_view) { FactoryBot.create :board_grid_with_query, name: 'My board', project: project }
  let(:project_html_title) { ::Components::HtmlTitle.new project }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

  before do
    with_enterprise_token :board_view
    project
    login_as(user)
  end

  it 'navigates from boards to the WP full view and back' do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query 'List 1', editable: true
    board_page.add_card 'List 1', 'Task 1'
    board_page.expect_notification message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq 'Task 1'
    # Double click leads to the full view
    click_target = board_page.find('[data-qa-selector="op-wp-single-card--content-type"]')
    page.driver.browser.action.double_click(click_target.native).perform

    expect(page).to have_current_path project_work_package_path(project, wp.id, 'activity')

    # Click back goes back to the board
    find('.work-packages-back-button').click
    expect(page).to have_current_path project_work_package_boards_path(project, board_view.id)

    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.expect_subject

    expect(page).to have_current_path /details\/#{wp.id}\/overview/
    card.expect_selected

    # Add a second card, focus on that
    board_page.add_card 'List 1', 'Foobar'
    board_page.expect_notification message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq 'Foobar'
    card = board_page.card_for(wp)

    # Click on the card
    card.card_element.click
    expect(page).to have_current_path /details\/#{wp.id}\/overview/
  end

  it 'navigates correctly the path from overview page to the boards page' do
    visit "/projects/#{project.identifier}"

    item = page.find('#menu-sidebar li[data-name="board_view"]', wait: 10)
    item.find('.toggler').click

    subitem = page.find('.main-menu--children-sub-item', text: 'My board', wait: 10)
    # Ends with boards due to lazy route
    expect(subitem[:href]).to end_with "/projects/#{project.identifier}/boards"

    subitem.click

    board_page = ::Pages::Board.new board_view
    board_page.expect_query 'List 1', editable: true
    board_page.add_card 'List 1', 'Task 1'
  end

  it 'navigates from boards to the WP details view then go to full view then go back (see #33747)' do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query 'List 1', editable: true
    board_page.add_card 'List 1', 'Task 1'
    board_page.expect_notification message: I18n.t(:notice_successful_create)

    wp = WorkPackage.last
    expect(wp.subject).to eq 'Task 1'
    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.expect_subject
    split_view.switch_to_tab tab: 'Relations'

    # Go to full view of WP
    full_view = split_view.switch_to_fullscreen
    full_view.expect_tab 'Relations'

    # Go back to details view with selected tab
    full_view.go_back
    split_view.expect_subject

    expect(page).to have_current_path /details\/#{wp.id}\/relations/
    split_view.expect_tab 'Relations'
  end

  before do
    with_enterprise_token :board_view
    project
    login_as(admin)
  end

  it 'navigates to boards after deleting WP(see #33756)' do
    board_index.visit!

    # Add a new WP on the board
    board_page = board_index.open_board board_view
    board_page.expect_query 'List 1', editable: true
    board_page.add_card 'List 1', 'Task 1'
    board_page.expect_notification message: I18n.t(:notice_successful_create)
    wp = WorkPackage.last
    expect(wp.subject).to eq 'Task 1'

    # Open the details page with the info icon
    card = board_page.card_for(wp)
    split_view = card.open_details_view
    split_view.expect_subject

    # Go to full view of WP
    split_view.switch_to_fullscreen
    find('#action-show-more-dropdown-menu').click
    click_link(I18n.t('js.button_delete'))

    # Delete the WP
    destroy_modal.expect_listed(wp)
    destroy_modal.confirm_deletion

    board_page.expect_empty
    board_page.expect_path
  end
end
