#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require 'support/pages/page'
require_relative './board_page'

module Pages
  class Board < Page

    def initialize(board)
      @board = board
    end

    def board(reload: false)
      @board.reload if reload

      yield @board if block_given?

      @board
    end

    def free?
      @board.options.type == 'free'
    end

    def action?
      !(free? || action_attribute.nil?)
    end

    def action_attribute
      @board.options.attribute
    end

    def card_view?
      board.options['display_mode'] == 'cards'
    end

    def list_count
      page.all('.board-list--container').count
    end

    def within_list(name, &block)
      page.within(list_selector(name), &block)
    end

    def list_selector(name)
      ".board-list--container[data-query-name='#{name}']"
    end

    def add_card(list_name, card_title)
      within_list(list_name) do
        page.find('.wp-inline-create--add-link').click
        subject = page.find('#wp-new-inline-edit--field-subject')
        subject.set card_title
        subject.send_keys :enter
      end

      expect_card(list_name, card_title)
    end

    ##
    # Expect the given titled card in the list name to be present (expect=true) or not (expect=false)
    def expect_card(list_name, card_title, present: true)
      within_list(list_name) do
        expect(page).to have_conditional_selector(present, '.work-package--card--subject', text: card_title)
      end
    end

    def move_card(index, from:, to:)
      source = page.all("#{list_selector(from)} .work-package--card")[index]
      target = page.find list_selector(to)

      scroll_to_element(source)
      page
        .driver
        .browser
        .action
        .move_to(source.native)
        .click_and_hold(source.native)
        .perform

      scroll_to_element(target)
      page
        .driver
        .browser
        .action
        .move_to(target.native)
        .release
        .perform
    end

    def add_list(name, value: nil)
      if value.nil? && action?
        raise "Must pass value option for action boards"
      end

      count = list_count
      page.find('.boards-list--add-item').click
      expect(page).to have_selector('.board-list--container', count: count + 1)

      rename_list 'New list', name
    end

    def remove_list(name)
      list = page.find list_selector(name)
      list.hover

      page.find('.board-list--delete-icon a').click
      accept_alert_dialog!
      expect_and_dismiss_notification message: I18n.t('js.notice_successful_update')

      expect(page).to have_no_selector list_selector(name)
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
      expect_and_dismiss_notification message: I18n.t('js.notice_successful_delete')
    end

    def back_to_index
      find('.board--back-button').click
    end

    def expect_editable(editable)
      # Editable / draggable check
      expect(page).to have_conditional_selector(editable, '.board--container.-editable')

      # Settings dropdown
      expect(page).to have_conditional_selector(editable, '.board--settings-dropdown')

      # Add new list
      expect(page).to have_conditional_selector(editable, '.boards-list--add-item')

      if editable
        expect(page).to have_selector('.wp-inline-create--add-link', count: list_count)
      else
        expect(page).to have_no_selector('.wp-inline-create--add-link')
      end
    end

    def rename_board(new_name, through_dropdown: false)
      if through_dropdown
        click_dropdown_entry 'Rename view'
        expect(page).to have_focus_on('.board--header-container .editable-toolbar-title--input')
        input = page.find('.board--header-container .editable-toolbar-title--input')
        input.set new_name
        input.send_keys :enter
      else
        page.within('.board--header-container') do
          input = page.find('.editable-toolbar-title--input').click
          input.set new_name
          input.send_keys :enter
        end
      end


      expect_and_dismiss_notification message: I18n.t('js.notice_successful_update')

      page.within('.board--header-container') do
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

      expect_and_dismiss_notification message: I18n.t('js.notice_successful_update')
    end

    def expect_query(name, editable: true)
      if editable
        expect(page).to have_field('editable-toolbar-title', with: name)
      else
        expect(page).to have_selector('.editable-toolbar-title--fixed', text: name)
      end
    end
  end
end
