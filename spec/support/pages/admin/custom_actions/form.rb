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
require "support/components/autocompleter/ng_select_autocomplete_helpers"

module Pages
  module Admin
    module CustomActions
      class Form < ::Pages::Page
        include ::Components::Autocompleter::NgSelectAutocompleteHelpers

        def set_name(name)
          fill_in "Name", with: name
        end

        def set_description(description)
          fill_in "Description", with: description
        end

        def add_action(name, value)
          ignore_ferrum_javascript_error do
            select name, from: "Add action"
          end
          set_action_value(name, value)
          within "#custom-actions-form--active-actions" do
            expect(page).to have_css(".form--label", text: name)
          end
        end

        def remove_action(name)
          within "#custom-actions-form--active-actions" do
            find(".form--field", text: name)
              .find(".icon-close")
              .click
          end
        end

        def expect_selected_option(value)
          expect(page).to have_css(".ng-value-label", text: value)
        end

        def expect_action(name, value)
          value = "null" if value.nil?

          within "#custom-actions-form--actions" do
            if value.is_a?(Array)
              value.each { |name| expect_selected_option(name.to_s) }
            else
              element = find("input[name='custom_action[actions][#{name}]']", visible: :all)
              expect(element.value).to eq value.to_s
            end
          end
        end

        def set_action(name, value)
          set_action_value(name, value)
        rescue Capybara::ElementNotFound
          add_action(name, value)
        end

        def set_condition(name, value)
          Array(value).each do |val|
            retry_block do
              set_condition_value(name, val)

              within "#custom-actions-form--conditions" do
                expect_selected_option val
              end
            end
          end
        end

        private

        def set_action_value(name, value)
          field = find("#custom-actions-form--active-actions .form--field", text: name, wait: 5)

          set_field_value(field, name, value)
        end

        def set_condition_value(name, value)
          field = find("#custom-actions-form--conditions .form--field", text: name, wait: 5)

          set_field_value(field, name, value)
        end

        def set_field_value(field, name, value)
          autocomplete = false

          Array(value).each do |val|
            within field do
              if has_selector?(".form--selected-value--container", wait: 0)
                find(".form--selected-value--container").click
                autocomplete = true
              elsif has_selector?(".autocomplete-select-decoration--wrapper", wait: 0)
                autocomplete = true
              end

              target = page.find_field(name)
              has_no_css?(".ng-spinner-loader") # wait for possible async loading of options for ng-select
              target.send_keys val
            end

            if autocomplete
              has_no_css?(".ng-spinner-loader") # wait for possible async loading of options for ng-select
              dropdown_el = find(".ng-option", text: val, wait: 5)
              scroll_to_and_click(dropdown_el)
            end
          end
        end
      end
    end
  end
end
