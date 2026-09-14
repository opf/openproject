# frozen_string_literal: true

module Components
  module Grids
    class GridArea
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      # The CSS grid uses doubled line numbers so that empty placeholder cells
      # (used as drag-and-drop targets) can be placed between every content cell.
      # Logical position 1 → CSS line 2, position 2 → CSS line 4, etc.
      # Use css_line and logical_position helpers to convert between the two.
      CSS_LINES_PER_LOGICAL_UNIT = 2

      attr_accessor :area_selector

      def initialize(*selector)
        self.area_selector = selector
      end

      def grid_value(style_name)
        area.style(style_name)[style_name].to_i
      end

      def logical_start_row
        grid_value("grid-row-start") / CSS_LINES_PER_LOGICAL_UNIT
      end

      def logical_start_col
        grid_value("grid-column-start") / CSS_LINES_PER_LOGICAL_UNIT
      end

      def resize_to(rows, cols)
        page.document.synchronize do
          current_area = area
          current_area.hover

          target_row = (grid_value_for(current_area, "grid-row-start") / CSS_LINES_PER_LOGICAL_UNIT) + rows - 1
          target_col = (grid_value_for(current_area, "grid-column-start") / CSS_LINES_PER_LOGICAL_UNIT) + cols - 1
          target = self.class.of(target_row * CSS_LINES_PER_LOGICAL_UNIT,
                                 target_col * CSS_LINES_PER_LOGICAL_UNIT)

          current_area.find(".grid--resizer").drag_to target.area
        end
      end

      def open_menu
        area.hover
        area.find("icon-triggered-context-menu").click
      end

      def click_menu_item(text)
        # Ensure there are no active toasters
        dismiss_toaster!

        open_menu

        SeleniumHubWaiter.wait
        click_link_or_button text
      end

      def expect_menu_item(text)
        # Ensure there are no active toasters
        dismiss_toaster!

        open_menu

        within("ul.dropdown-menu") do |element|
          expect(element).to have_css("span", text:)
        end
      end

      def remove
        click_menu_item(I18n.t("js.grid.remove"))
      end

      def configure_wp_table
        click_menu_item(I18n.t("js.toolbar.settings.configure_view"))
      end

      def drag_to(row, column)
        handle = drag_handle
        target = self.class.of(row * 2, column * 2)

        scroll_to_element(handle)

        move_to(handle) do |action|
          action.click_and_hold(handle.native)
        end

        scroll_to_element(target.area)
        target.area.hover

        sleep(1)

        # `target.area` calls page.find on each access, so this re-queries the DOM
        # to get a fresh native reference after CDK drag has updated it.
        move_to(target.area, &:release)
      end

      def expect_to_exist
        expect(page)
          .to have_selector(*area_selector)
      end

      def expect_to_span(start_row, start_column, end_row, end_column)
        errors = page.driver.invalid_element_errors + [
          Capybara::ElementNotFound,
          RSpec::Expectations::ExpectationNotMetError
        ]
        page.document.synchronize(errors:) do
          current_area = area
          [["grid-row-start", start_row * 2],
           ["grid-column-start", start_column * 2],
           ["grid-row-end", (end_row * 2) - 1],
           ["grid-column-end", (end_column * 2) - 1]].each do |style, expected|
            actual = current_area.style(style)

            expect(actual).to eql({ style => expected.to_s }),
                              "expected #{style} to be #{expected} but it is #{actual}"
          end
        end
      end

      def expect_not_resizable
        within area do
          expect(page)
            .to have_no_css(".grid--area.-widgeted resizer")
        end
      end

      def expect_not_draggable
        area.hover

        within area do
          expect(page)
            .to have_no_css(".grid--area-drag-handle")
        end
      end

      def expect_not_renameable
        within area do
          expect(page)
            .to have_css(".editable-toolbar-title--fixed")
        end
      end

      def expect_no_menu
        area.hover

        within area do
          expect(page)
            .to have_no_css(".icon-show-more-horizontal")
        end
      end

      def area
        page.find(*area_selector)
      end

      def grid_value_for(element, style_name)
        element.style(style_name)[style_name].to_i
      end

      def drag_handle
        area.hover
        area.find(".cdk-drag-handle")
      end

      def self.of(row_number, column_number)
        area_style = "grid-area: #{row_number} / #{column_number} / #{row_number + 1} / #{column_number + 1}"

        new(".grid--area:not(.-widgeted)[style*='#{area_style}']")
      end

      def move_to(element)
        action = page
                 .driver
                 .browser
                 .action
                 .move_to(element.native)

        yield action

        action.perform
      end

      def dismiss_toaster!
        if page.has_selector?(".op-toast--close")
          page.find(".op-toast--close").click
        end

        expect(page).to have_no_css(".op-toast")
      end
    end
  end
end
