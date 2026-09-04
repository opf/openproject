# frozen_string_literal: true

require_relative "form_field"

module FormFields
  module Primerized
    class AutocompleteField < FormField
      include RSpec::Wait
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      ### actions

      def select_option(*values)
        values.each do |val|
          open_options

          expect(page).to have_css(".ng-option", text: val, visible: :all)
          page.find(".ng-option", text: val, visible: :all).click
          expect_selected(val)
        end
      end

      def deselect_option(*values)
        values.each do |val|
          open_options
          page.find(".ng-value", text: val, visible: :all).find(".ng-value-icon").click
          expect_not_selected(val)
        end
        field_container.find(".ng-input input").send_keys(:escape)
        expect(field_container).to have_no_css("ng-select.ng-select-opened")
      end

      def search(text)
        search_autocomplete(-> { field_container }, query: text)
      end

      # For remote typeahead autocompleters, where options are only loaded for
      # the typed search term. Unlike select_option, it does not reopen the
      # dropdown, as that would discard the term.
      def search_and_select_option(*values)
        values.each do |value|
          search(value)
          wait_for_autocompleter_options_to_be_loaded
          page.find(".ng-option", text: value, visible: :all).click
        end
      end

      def close_autocompleter
        if page.has_css?(".ng-select-container input", wait: 0.1)
          field_container.find(".ng-select-container input").send_keys :escape
        end
      end

      def open_options
        wait_for_autocompleter_options_to_be_loaded
        wait(timeout: 3).for do
          # click the arrow to prevent clicking inside the input field and
          # risking to remove some elements in a mult-select (clicking the "x")
          # this may close the dropdown, but it will be clicked again if it's not open anyway.
          field_container.find(".ng-select-container .ng-arrow-wrapper").click
          page
        end.to have_css(".ng-dropdown-panel-items", wait: 0.25)
      end

      def clear
        field_container.find(".ng-clear-wrapper", visible: :all).click
      end

      ### expectations

      def expect_selected(*values)
        values.each do |val|
          expect(field_container).to have_css(".ng-value", text: val)
        end
      end

      def expect_not_selected(*values)
        values.each do |val|
          expect(field_container).to have_no_css(".ng-value", text: val, wait: 1)
        end
      end

      def expect_disabled(*values)
        values.each do |val|
          expect(page).to have_css(".ng-option.ng-option-disabled", text: val)
        end
      end

      def expect_not_disabled(*values)
        values.each do |val|
          expect(page).to have_no_css(".ng-option.ng-option-disabled", text: val, wait: 1)
        end
      end

      def expect_blank
        expect(field_container).to have_css(".ng-value", count: 0)
      end

      def expect_no_option(option)
        expect(page)
          .to have_no_css(".ng-option", text: option, visible: :all, wait: 1)
      end

      def expect_option(option, grouping: nil)
        if grouping
          # Make sure the option is displayed under correct grouping title.
          option_group = find(".ng-optgroup", text: grouping)
          option = find(".ng-option.ng-option-child", text: option, visible: :visible)

          expected_group = begin
            option.find(:xpath,
                        "preceding-sibling::*[contains(@class, 'ng-optgroup')][1]",
                        wait: false)
          rescue Capybara::ElementNotFound
            raise "Unable to find the '.ng-optgroup' grouping for option '#{option.text}'"
          end

          expect(option_group).to eq(expected_group), <<~MSG
            Expected the option '#{option.text}' to be under the group '#{option_group.text}',
            but it was under '#{expected_group.text}' instead.
          MSG
        else
          expect(page)
            .to have_css(".ng-option", text: option, visible: :visible)
        end
      end

      def expect_visible
        expect(field_container).to have_css("ng-select")
      end

      def expect_error(string = nil)
        expect(field_container).to have_css(".FormControl-inlineValidation", visible: :all)
        expect(field_container).to have_text(string) if string
      end
    end
  end
end
