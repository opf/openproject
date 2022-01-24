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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'support/pages/page'
require_relative './board_page'

module Pages
  class Board < Page
    include ::Components::NgSelectAutocompleteHelpers

    def initialize(board)
      @board = board
    end

    def board(reload: false)
      @board.reload if reload

      yield @board if block_given?

      @board
    end

    def free?
      @board.options['type'] == 'free'
    end

    def action?
      !(free? || action_attribute.nil?)
    end

    def expect_path
      expect(page).to have_current_path /boards\/#{@board.id}/
    end

    def action_attribute
      @board.options['attribute']
    end

    def list_count
      page.all('[data-qa-selector="op-board-list"]').count
    end

    def within_list(name, &block)
      page.within(list_selector(name), &block)
    end

    def list_selector(name)
      "[data-qa-selector='op-board-list'][data-query-name='#{name}']"
    end

    def add_card(list_name, card_title)
      within_list(list_name) do
        page.find('[data-qa-selector="op-board-list--card-dropdown-add-button"]').click
      end

      # Add item in dropdown
      page.find('.menu-item', text: 'Add new card').click

      subject = page.find('#wp-new-inline-edit--field-subject')
      subject.set card_title
      subject.send_keys :enter

      sleep 1

      expect_card(list_name, card_title)
    end

    def remove_card(list_name, card_title, index)
      source = page.all("#{list_selector(list_name)} [data-qa-selector='op-wp-single-card']")[index]
      source.hover
      source.find('[data-qa-selector="op-wp-single-card--inline-cancel-button"]').click

      expect_card(list_name, card_title, present: false)
    end

    def reference(list_name, work_package)
      within_list(list_name) do
        page.find('[data-qa-selector="op-board-list--card-dropdown-add-button"]').click
      end

      page.find('.menu-item', text: 'Add existing').click

      select_autocomplete(page.find('.wp-inline-create--reference-autocompleter'),
                          query: work_package.subject,
                          results_selector: 'body',
                          select_text: "##{work_package.id}")

      expect_card(list_name, work_package.subject)
    end

    def expect_not_referencable(list_name, work_package)
      within_list(list_name) do
        page.find('[data-qa-selector="op-board-list--card-dropdown-add-button"]').click
      end

      page.find('.menu-item', text: 'Add existing').click

      target_dropdown = search_autocomplete(page.find('.wp-inline-create--reference-autocompleter'),
                                            query: work_package.subject,
                                            results_selector: '.work-packages-partitioned-query-space--container')

      expect(target_dropdown).to have_no_selector('.ui-menu-item', text: work_package.subject)
    end

    ##
    # Expect the given titled card in the list name to be present (expect=true) or not (expect=false)
    def expect_card(list_name, card_title, present: true)
      within_list(list_name) do
        expect(page).to have_conditional_selector(present, '[data-qa-selector="op-wp-single-card--content-subject"]', text: card_title)
      end
    end

    ##
    # Expect the given work packages (or their subjects) to be listed in that exact order in the list.
    # No non mentioned cards are allowed to be in the list.
    def expect_cards_in_order(list_name, *card_titles)
      within_list(list_name) do
        found = all('[data-qa-selector="op-wp-single-card--content-subject"]')
          .map(&:text)
        expected = card_titles.map { |title| title.is_a?(WorkPackage) ? "##{title.id} #{title.subject}" : title.to_s }

        expect(found)
          .to match expected
      end
    end

    def expect_movable(list_name, card_title, movable: true)
      within_list(list_name) do
        expect(page).to have_selector('[data-qa-selector="op-wp-single-card"]', text: card_title)
        expect(page).to have_conditional_selector(movable, '[data-qa-selector="op-wp-single-card"][data-qa-draggable]', text: card_title)
      end
    end

    def move_card(index, from:, to:)
      source = page.all("#{list_selector(from)} [data-qa-selector='op-wp-single-card']")[index]
      target = page.find list_selector(to)

      drag_n_drop_element(from: source, to: target)
    end

    def add_list(option: nil, query: option)
      if option.nil? && action?
        raise "Must pass value option for action boards"
      end

      count = list_count

      if option.nil?
        page.find('.boards-list--add-item').click
        expect(page).to have_selector('[data-qa-selector="op-board-list"]', count: count + 1)
      else
        open_and_fill_add_list_modal query
        page.find('.ng-option', text: option, wait: 10).click
        page.find('.confirm-form-submit--submit').click
      end
    end

    def add_list_with_new_value(name)
      open_and_fill_add_list_modal name

      page.find('.op-select-footer--label', text: 'Create ' + name).click
    end

    def save
      page.find('.editable-toolbar-title--save').click
      expect_and_dismiss_toaster message: 'Successful update.'
    end

    def expect_changed
      expect(page).to have_selector('.editable-toolbar-title--save')
    end

    def expect_not_changed
      expect(page).to have_no_selector('.editable-toolbar-title--save')
    end

    def expect_list(name)
      expect(page).to have_selector('[data-qa-selector="op-board-list--header"]', text: name, wait: 10)
    end

    def expect_no_list(name)
      expect(page).not_to have_selector('[data-qa-selector="op-board-list--header"]', text: name)
    end

    def expect_empty
      expect(page).to have_no_selector('.boards-list--item', wait: 10)
    end

    def remove_list(name)
      click_list_dropdown name, 'Delete list'

      accept_alert_dialog!
      expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')

      expect(page).to have_no_selector list_selector(name)
    end

    def click_list_dropdown(list_name, action)
      within_list(list_name) do
        page.find('[data-qa-selector="op-board-list--header"]').hover
        page.find('[data-qa-selector="op-board-list--menu"] a').click
      end

      page.find('.dropdown-menu button', text: action).click
    end

    def card_for(work_package)
      ::Pages::WorkPackageCard.new work_package
    end

    def expect_list_option(name, present: true)
      open_and_fill_add_list_modal name

      if present
        expect(page).to have_selector('.ng-option', text: name)
      else
        expect(page).not_to have_selector('.ng-option', text: name)
      end
      find('body').send_keys [:escape]
    end

    def visit!
      if board.project
        visit project_work_package_boards_path(project_id: board.project.id, state: board.id)
      else
        visit work_package_boards_path(state: board.id)
      end
    end

    def delete_board
      click_dropdown_entry 'Delete'

      accept_alert_dialog!
      expect_and_dismiss_toaster message: I18n.t('js.notice_successful_delete')
    end

    def back_to_index
      find('[data-qa-selector="op-back-button"]').click
    end

    def expect_editable_board(editable)
      # Settings dropdown
      expect(page).to have_conditional_selector(editable, '.board--settings-dropdown')

      # Add new list
      expect(page).to have_conditional_selector(editable, '.boards-list--add-item')
    end

    def expect_editable_list(editable)
      expect(page).to have_conditional_selector(editable, '[data-qa-selector="op-board-list--card-dropdown-add-button"]')
    end

    def rename_board(new_name, through_dropdown: false)
      if through_dropdown
        click_dropdown_entry 'Rename view'
        expect(page).to have_focus_on('.toolbar-container .editable-toolbar-title--input')
        input = page.find('.toolbar-container .editable-toolbar-title--input')
        input.set new_name
        input.send_keys :enter
      else
        page.within('.toolbar-container') do
          input = page.find('.editable-toolbar-title--input').click
          input.set new_name
          input.send_keys :enter
        end
      end

      expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')

      page.within('.toolbar-container') do
        expect(page).to have_field('editable-toolbar-title', with: new_name)
      end
    end

    def click_dropdown_entry(name)
      page.find('.board--settings-dropdown').click
      page.find('.menu-item', text: name).click
    end

    def rename_list(from, to)
      input = page.find_field('editable-toolbar-title', with: from).click
      input.set to
      input.send_keys :enter

      expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')
    end

    def expect_query(name, editable: true)
      if editable
        expect(page).to have_field('editable-toolbar-title', with: name)
      else
        expect(page).to have_selector('.editable-toolbar-title--fixed', text: name)
      end
    end

    def change_board_highlighting(mode, attribute = nil)
      click_dropdown_entry 'Configure view'

      if attribute.nil?
        choose(option: mode)
      else
        select attribute, from: 'selected_attribute'
      end

      click_button 'Apply'
    end

    def open_and_fill_add_list_modal(name)
      open_add_list_modal
      sleep(0.1)
      page.find('.op-modal .new-list--action-select input').set(name)
    end

    def open_add_list_modal
      page.find('.boards-list--add-item').click
      expect(page).to have_selector('.new-list--action-select input')
    end

    def add_list_modal_shows_warning(value, with_link: false)
      within page.find('.op-modal') do
        warning = '.op-toast.-warning'
        link = '.op-toast--content a'

        expect(page).to (value ? have_selector(warning) : have_no_selector(warning))
        expect(page).to (with_link ? have_selector(link) : have_no_selector(link))
      end
    end
  end
end
