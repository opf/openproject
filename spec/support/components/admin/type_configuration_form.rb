#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module Components
  module Admin
    class TypeConfigurationForm
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def add_button_dropdown
        page.find '.form-configuration--add-group', text: 'Group'
      end

      def add_attribute_group_button
        page.find 'a', text: I18n.t('js.admin.type_form.add_group')
      end

      def add_table_button
        page.find 'a', text: I18n.t('js.admin.type_form.add_table')
      end

      def reset_button
        page.find '.form-configuration--reset'
      end

      def inactive_group
        page.find '#type-form-conf-inactive-group'
      end

      def inactive_drop
        page.find '#type-form-conf-inactive-group .attributes'
      end

      def find_group(name)
        head = page.find('.group-head', text: name.upcase)

        # Return the parent of the group-head
        head.find(:xpath, '..')
      end

      def checkbox_selector(attribute)
        ".type-form-conf-attribute[data-key='#{attribute}'] .attribute-visibility input"
      end

      def attribute_selector(attribute)
        ".type-form-conf-attribute[data-key='#{attribute}']"
      end

      def find_group_handle(label)
        find_group(label).find(".group-handle")
      end

      def find_attribute_handle(attribute)
        page.find("#{attribute_selector(attribute)} .attribute-handle")
      end

      def expect_attribute(key:, translation: nil)
        attribute = page.find(attribute_selector(key))

        unless translation.nil?
          expect(attribute).to have_selector('.attribute-name', text: translation)
        end
      end

      def move_to(attribute, group_label)
        handle = find_attribute_handle(attribute)
        group = find_group(group_label)
        drag_and_drop(handle, group)
        expect_group(group_label, group_label, key: attribute)
      end

      def remove_attribute(attribute)
        attribute = page.find(attribute_selector(attribute))
        attribute.find('.delete-attribute').click
      end

      def drag_and_drop(handle, group)
        target = group.find('.attributes')

        scroll_to_element(group)
        page
          .driver
          .browser
          .action
          .move_to(handle.native)
          .click_and_hold(handle.native)
          .perform

        scroll_to_element(group)
        page
          .driver
          .browser
          .action
          .move_to(target.native)
          .release
          .perform
      end

      def add_query_group(name, relation_filter, expect: true)
        add_button_dropdown.click
        add_table_button.click

        modal = ::Components::WorkPackages::TableConfigurationModal.new

        within find('.relation-filter-selector') do
          select I18n.t("js.relation_labels.#{relation_filter}")

          # While we are here, let's check that all relation filters are present.
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
        modal.save

        input = find('.group-edit-in-place--input')
        input.set(name)
        input.send_keys(:return)

        expect_group(name, name) if expect
      end

      def edit_query_group(name)
        group = find_group(name)
        group.find('.type-form-query-group--edit-button').click
      end

      def add_attribute_group(name, expect: true)
        add_button_dropdown.click
        add_attribute_group_button.click

        input = find('.group-edit-in-place--input')
        input.set(name)
        input.send_keys(:return)

        expect_group(name, name) if expect
      end

      def save_changes
        # Save configuration
        # click_button doesn't seem to work when the button is out of view!?
        scroll_to_and_click find('.form-configuration--save')
      end

      def rename_group(from, to)
        find('.group-edit-handler', text: from.upcase).click

        input = find('.group-edit-in-place--input')
        input.click
        input.set(to)
        input.send_keys(:return)

        expect(page).to have_selector('.group-edit-handler', text: to.upcase)
      end

      def expect_no_attribute(attribute, group)
        expect(find_group(group)).not_to have_selector("#{attribute_selector(attribute)}")
      end

      def expect_group(label, translation, *attributes)
        expect(find_group(translation)).to have_selector(".group-edit-handler", text: translation.upcase)

        within find_group(translation) do
          attributes.each do |attribute|
            expect_attribute(attribute)
          end
        end
      end

      def expect_inactive(attribute)
        expect(inactive_drop).to have_selector(".type-form-conf-attribute[data-key='#{attribute}']")
      end
    end
  end
end
