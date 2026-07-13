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

module Components
  module Admin
    class TypeConfigurationForm
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include Rails.application.routes.url_helpers

      def add_button_dropdown
        page.find_test_selector("type-form-configuration-add-button")
      end

      def reset_button
        page.find_test_selector("type-form-configuration-reset-button")
      end

      def inactive_group
        page.find_test_selector("type-form-configuration-inactive-container")
      end

      def inactive_drop
        inactive_group.find("[data-test-selector='type-form-configuration-inactive-list']")
      end

      def expect_empty
        expect(page).to have_no_css("[data-group-key]")
      end

      def find_group(name)
        page.find(:xpath, group_xpath(name))
      end

      def attribute_selector(attribute)
        %[li[data-attr-key="#{attribute}"]]
      end

      def find_group_handle(label)
        group_key = find_group(label)["data-group-key"]
        page.find_test_selector("type-form-configuration-group-handle-#{group_key}", visible: :all)
      end

      def find_attribute_handle(attribute)
        page.find_test_selector("type-form-configuration-attribute-handle-#{attribute}", visible: :all)
      end

      def expect_attribute(key:, translation: nil)
        attribute = page.find(attribute_selector(key))
        expect(attribute).to have_text(translation) if translation
      end

      def move_to(attribute, group_label)
        drag_and_drop(find_attribute_handle(attribute), find_group(group_label))
        expect_group(group_label, group_label, key: attribute)
      end

      def remove_attribute(attribute)
        row = page.find(attribute_selector(attribute))

        within row do
          page.find_test_selector("type-form-configuration-attribute-actions-#{attribute}").click
        end

        page.find_test_selector("type-form-configuration-delete-attribute-#{attribute}", visible: :all).click

        page.within_test_selector("type-form-configuration-groups-container") do
          expect(page).to have_no_css(attribute_selector(attribute))
        end
      end

      def drag_and_drop(handle, target)
        target_container = drop_container_for(target)
        source_row = handle.find(:xpath, "./ancestor::li[1]")

        scroll_to_element(target_container)
        source_row.hover

        page.driver.browser.action
            .move_to(handle.native)
            .click_and_hold(handle.native)
            .perform

        scroll_to_element(target_container)

        target_container.all(":scope > li", visible: true).each do |item|
          page.driver.browser.action
              .move_to(item.native)
              .perform
        end

        page.driver.browser.action
            .move_to(target_container.native)
            .release
            .perform
      end

      def add_query_group(name, relation_filter, expect: true)
        SeleniumHubWaiter.wait unless using_cuprite?

        add_button_dropdown.click
        page.find_test_selector("admin--type-form-configuration--add-query-group").click

        modal = ::Components::WorkPackages::TableConfigurationModal.new
        expect(page).to have_css(".wp-table--configuration-modal", wait: 10)

        unless relation_filter.to_sym == :children
          within ".relation-filter-selector" do
            option_label = displayed_relation_filter_label(relation_filter)
            expect(page).to have_css(".relation-filter-selector option", text: option_label, wait: 10)

            relation_select = page.find_test_selector("wp-table-configuration-relation-filter", visible: :all)
            relation_select.find(:option, option_label, wait: 10).select_option

            option_labels = %w[
              children
              precedes
              follows
              relates
              duplicates
              duplicated
              blocks
              blocked
              partof
              includes
              requires
              required
            ].map { |filter_name| I18n.t("js.relation_labels.#{filter_name}") }

            option_labels.each do |label|
              expect(page).to have_text(label)
            end
          end
        end

        yield modal if block_given?
        modal.save if modal.open?

        fill_group_name(name)
        save_group

        expect_group(name, name) if expect
      end

      def edit_query_group(name)
        wait_for_turbo

        group_key = find_group(name)["data-group-key"]
        menu_id = open_query_menu(name)
        page.find("##{menu_id}", visible: :all)
            .find(:test_id, "type-form-configuration-edit-query-#{group_key}", visible: :all)
            .click
        expect(page).to have_css(".wp-table--configuration-modal")
      end

      def edit_query_group_via_link(name)
        wait_for_turbo

        group = find_group(name)
        label = I18n.t("types.edit.form_configuration.query_group_label")
        group.click_button(label)
        expect(page).to have_css(".wp-table--configuration-modal")
      end

      def add_attribute_group(name, expect: true)
        add_button_dropdown.click
        click_on I18n.t("types.edit.form_configuration.add_attribute_group")

        fill_group_name(name)
        save_group

        expect_group(name, name) if expect
      end

      def save_changes
        wait_for_turbo
      end

      def rename_group(from, to)
        group_key = find_group(from)["data-group-key"]
        open_group_menu(from)
        page.find_test_selector("type-form-configuration-group-rename-#{group_key}", visible: :all).click

        fill_group_name(to)
        save_group

        expect_group(to, to)
      end

      def remove_group(name)
        accept_confirm I18n.t("types.edit.form_configuration.confirm_delete_group") do
          menu_id = open_group_menu(name)
          within "##{menu_id}" do
            click_link I18n.t("button_delete")
          end
        end

        expect(page).to have_no_css("[data-group-key]", text: /\b#{Regexp.escape(name)}\b/)
      end

      def expect_no_attribute(attribute, group)
        expect(find_group(group)).to have_no_css(attribute_selector(attribute))
      end

      def expect_group(_label, translation, *attributes)
        group = find_group(translation)
        expect(group).to have_text(translation)

        within group do
          attributes.each do |attribute|
            expect_attribute(**attribute)
          end
        end
      end

      def expect_inactive(attribute)
        expect(inactive_drop).to have_css(attribute_selector(attribute))
      end

      def group_order
        page.within_test_selector("type-form-configuration-groups-container") do
          all(":scope > [data-group-key] .Box-header span.text-bold", visible: true).map(&:text)
        end
      end

      def attribute_order(group_name)
        find_group(group_name).find("ul").all(":scope > li[data-attr-key]", visible: true).pluck("data-attr-key")
      end

      def open_attribute_menu(attribute)
        open_menu("type-form-configuration-attribute-actions-#{attribute}")
      end

      def open_query_menu(name)
        group_key = find_group(name)["data-group-key"]
        open_menu("type-form-configuration-query-actions-#{group_key}")
      end

      def invoke_group_action(name, label)
        click_menu_action(-> { open_group_menu(name) }, label)
        wait_for_turbo
      end

      def invoke_attribute_action(attribute, label)
        click_menu_action(-> { open_attribute_menu(attribute) }, label)
        wait_for_turbo
      end

      private

      def drop_container_for(target)
        inactive_list_selector = "[data-test-selector='type-form-configuration-inactive-list']"

        if target.has_css?(inactive_list_selector, wait: 0)
          target.find(inactive_list_selector)
        else
          target.find(".Box ul")
        end
      end

      def displayed_relation_filter_label(relation_filter)
        I18n.t("js.relation_labels.#{relation_filter}")
      end

      def fill_group_name(name)
        input = page.find_test_selector("type-form-configuration-group-name-input", wait: 10)
        input.set(name)
      end

      def open_group_menu(name)
        menu_id = nil

        3.times do
          menu_button = menu_button_for(name)
          menu_id = menu_button[:"aria-controls"]
          menu_button.click

          return menu_id if page.has_css?("##{menu_id}", visible: :all, wait: 2)
        rescue Selenium::WebDriver::Error::StaleElementReferenceError, Capybara::ElementNotFound
          next
        end

        raise Capybara::ElementNotFound, "Unable to open menu #{menu_id.inspect}"
      end

      def menu_button_for(name)
        group_key = find_group(name)["data-group-key"]
        page.find_test_selector("type-form-configuration-group-actions-#{group_key}")
      end

      def open_menu(button_selector)
        menu_id = nil
        menu_button = nil

        3.times do
          menu_button = page.find_test_selector(button_selector)
          menu_id = menu_button[:"aria-controls"]
          menu_button.click
          return menu_id if page.has_css?("##{menu_id}", visible: :all, wait: 2)
        rescue Capybara::Cuprite::MouseEventFailed
          menu_button&.trigger("click")
          return menu_id if page.has_css?("##{menu_id}", visible: :all, wait: 2)
        rescue Selenium::WebDriver::Error::StaleElementReferenceError, Capybara::ElementNotFound
          next
        end

        raise Capybara::ElementNotFound, "Unable to open menu #{menu_id.inspect}"
      end

      def click_menu_action(open_menu_callback, label)
        retry_block(args: { tries: 3 }) do
          menu_id = open_menu_callback.call
          menu = page.find("##{menu_id}", visible: :all)
          menu.first("[role='menuitem']", text: /\A#{Regexp.escape(label)}\z/, visible: :all).click
        end
      end

      def save_group
        page.find_test_selector("type-form-configuration-group-save", wait: 10).click
        expect(page).to have_no_selector(page.test_selector("type-form-configuration-group-name-input"))
      end

      def wait_for_turbo
        if using_cuprite?
          wait_for_reload
        else
          SeleniumHubWaiter.wait
        end
      end

      def group_xpath(name)
        <<~XPATH.squish
          //*[@data-group-key]
            [.//span[contains(concat(' ', normalize-space(@class), ' '), ' text-bold ')
            and normalize-space()=#{xpath_literal(name)}]]
        XPATH
      end

      def xpath_literal(value)
        if value.include?("'")
          parts = value.split("'").map { |part| "'#{part}'" }
          %(concat(#{parts.join(%q{, "'", })}))
        else
          "'#{value}'"
        end
      end
    end
  end
end
