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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Forms
    # Drives a form's page; groups are addressed by name, attributes by key.
    class Edit < ::Pages::Page
      def initialize(form)
        super()
        @form = form
      end

      def path
        "/forms/#{@form.id}/edit"
      end

      def group(name)
        groups_container.find(:heading, text: name, exact_text: true).ancestor(".Box")
      end

      def expect_group_order(*names)
        page.document.synchronize do
          found = group_names
          raise Capybara::ExpectationNotMet, "Expected groups #{names}, got #{found}" unless found == names
        end
      end

      def expect_groups_starting_with(*names)
        page.document.synchronize do
          found = group_names
          next if found.first(names.size) == names

          raise Capybara::ExpectationNotMet, "Expected groups to start with #{names}, got #{found}"
        end
      end

      def expect_group_in_view(name)
        expect(groups_container).to have_selector(:heading, text: name, exact_text: true, obscured: false)
      end

      def expect_group_out_of_view(name)
        expect(groups_container).to have_selector(:heading, text: name, exact_text: true, obscured: true)
      end

      def expect_empty_state(group_name)
        expect(group(group_name)).to have_heading(I18n.t("types.edit.form_configuration.empty_group_title"))
      end

      def expect_no_empty_state(group_name)
        expect(group(group_name)).to have_no_heading(I18n.t("types.edit.form_configuration.empty_group_title"))
      end

      def expect_attributes(group_name, *keys)
        expected = keys.map(&:to_s)

        page.document.synchronize do
          found = group(group_name).all("li[data-attr-key]").map { it["data-attr-key"] }
          raise Capybara::ExpectationNotMet, "Expected #{expected} in #{group_name}, got #{found}" unless found == expected
        end
      end

      def expect_inactive(*keys)
        keys.each { expect(inactive_list).to have_css(row_selector(it)) }
      end

      def expect_hidden_in_inactive(key)
        expect(inactive_list).to have_css(row_selector(key), visible: :hidden)
      end

      def drag_group(name, below:)
        target = group(below)

        perform_native_drag(source: drag_handle(group(name).find(".Box-header")),
                            target:,
                            offset_y: (target.native.rect.height / 2) - 4)
      end

      def drag_group_to_list_end(name)
        handle = drag_handle(group(name).find(".Box-header"))
        scroller = page.find(".type-form-configuration-page--active-list")

        page.driver.browser.action
            .move_to(handle.native)
            .click_and_hold(handle.native)
            .pause(duration: 0.1)
            .move_to(scroller.native, 0, (scroller.native.rect.height / 2) - 6)
            .pause(duration: 1.5)
            .move_by(0, 1)
            .pause(duration: 1.5)
            .move_by(0, -40)
            .pause(duration: 0.1)
            .release
            .perform
      end

      def drag_attribute(key, to_group: nil, to_inactive: false)
        target = to_inactive ? inactive_list : group(to_group).find("ul")

        perform_native_drag(source: drag_handle(row(key)), target:)
      end

      def drag_attribute_beside(key, above: nil, below: nil)
        target = row(above || below)
        edge = (target.native.rect.height / 2) - 4

        perform_native_drag(source: drag_handle(row(key)), target:, offset_y: above ? -edge : edge)
      end

      def move_group(name, label)
        within_group_menu(name) { |menu| menu.find(:menuitem, label, exact: true).click }
      end

      def move_attribute(key, label)
        within_attribute_menu(key) { |menu| menu.find(:menuitem, label, exact: true).click }
      end

      def expect_group_moves(name, offered:, absent:)
        within_group_menu(name) { |menu| expect_menu_entries(menu, offered:, absent:) }
      end

      def expect_attribute_moves(key, offered:, absent:)
        within_attribute_menu(key) { |menu| expect_menu_entries(menu, offered:, absent:) }
      end

      def start_renaming(name)
        within_group_menu(name) do |menu|
          menu.find(:menuitem, I18n.t("types.edit.form_configuration.rename_group"), exact: true).click
        end

        expect(page).to have_field(with: name)
      end

      def expect_inactive_empty_state
        expect(page.find_by_id("type-form-configuration-inactive-container"))
          .to have_heading(I18n.t("types.edit.form_configuration.no_inactive_attributes"))
      end

      def expect_no_inactive_empty_state
        expect(page.find_by_id("type-form-configuration-inactive-container"))
          .to have_no_heading(I18n.t("types.edit.form_configuration.no_inactive_attributes"))
      end

      def filter_inactive(text)
        page.fill_in I18n.t("types.edit.form_configuration.filter_inactive"), with: text
      end

      private

      def groups_container
        page.find_by_id("type-form-configuration-groups-container")
      end

      def group_names
        groups_container.all(".Box-header").map { group_name_in(it) }
      end

      def group_name_in(header)
        field = header.first(:field, I18n.t("types.edit.form_configuration.group_name_label"), minimum: 0, wait: false)
        return field.value if field

        header.find(:heading).text
      end

      def inactive_list
        page.find_by_id("type-form-configuration-inactive-container").find(".Box > ul")
      end

      def row(key)
        page.find(row_selector(key))
      end

      def row_selector(key)
        "li[data-attr-key='#{key}']"
      end

      def drag_handle(scope)
        scope.find(:button, accessible_name: I18n.t("types.edit.form_configuration.drag_to_reorder"))
      end

      def within_group_menu(name, &)
        button = group(name).find(".Box-header")
                            .find(:button, accessible_name: I18n.t("types.edit.form_configuration.group_actions"))

        within(open_controlled_menu(button), &)
      end

      def within_attribute_menu(key, &)
        button = row(key).find(:button, accessible_name: I18n.t("types.edit.form_configuration.row_actions"))

        within(open_controlled_menu(button), &)
      end

      def open_controlled_menu(button)
        button.click
        page.find(:menu, id: button["aria-controls"])
      end

      def expect_menu_entries(menu, offered:, absent:)
        offered.each { expect(menu).to have_selector(:menuitem, it, exact: true) }
        absent.each { expect(menu).to have_no_selector(:menuitem, it, exact: true) }
        page.send_keys(:escape)
      end
    end
  end
end
