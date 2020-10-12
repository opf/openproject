module Components
  module Grids
    class GridArea
      include Capybara::DSL
      include RSpec::Matchers

      attr_accessor :area_selector

      def initialize(*selector)
        self.area_selector = selector
      end

      def resize_to(row, column)
        area.hover

        area.find('.grid--resizer').drag_to self.class.of(row * 2, column * 2).area
      end

      def open_menu
        area.hover
        area.find('icon-triggered-context-menu').click
      end

      def click_menu_item(text)
        # Ensure there are no active notifications
        dismiss_notification!

        open_menu

        find('a.menu-item', text: text).click
      end

      def remove
        click_menu_item(I18n.t('js.grid.remove'))
      end

      def configure_wp_table
        click_menu_item(I18n.t('js.toolbar.settings.configure_view'))
      end

      def drag_to(row, column)
        handle = drag_handle
        drop_area = self.class.of(row * 2, column * 2).area

        scroll_to_element(handle)

        move_to(handle) do |action|
          action.click_and_hold(handle.native)
        end

        scroll_to_element(drop_area)
        drop_area.hover

        sleep(1)

        move_to(drop_area, &:release)
      end

      def expect_to_exist
        expect(page)
          .to have_selector(*area_selector)
      end

      def expect_to_span(startRow, startColumn, endRow, endColumn)
        [['grid-row-start', startRow * 2],
         ['grid-column-start', startColumn * 2],
         ['grid-row-end', endRow * 2 - 1],
         ['grid-column-end', endColumn * 2 - 1]].each do |style, expected|

          actual = area.native.style(style)

          expect(actual)
            .to eql(expected.to_s), "expected #{style} to be #{expected} but it is #{actual}"
        end
      end

      def expect_not_resizable
        within area do
          expect(page)
            .to have_no_selector('.grid--area.-widgeted resizer')
        end
      end

      def expect_not_draggable
        area.hover

        within area do
          expect(page)
            .to have_no_selector(".grid--area-drag-handle")
        end
      end

      def expect_not_renameable
        within area do
          expect(page)
            .to have_selector(".editable-toolbar-title--fixed")
        end
      end

      def expect_no_menu
        area.hover

        within area do
          expect(page)
            .to have_no_selector(".icon-show-more-horizontal")
        end
      end

      def area
        page.find(*area_selector)
      end

      def drag_handle
        area.hover
        area.find('.cdk-drag-handle')
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

      def dismiss_notification!
        if page.has_selector?('.notification-box--close')
          page.find('.notification-box--close').click
        end

        expect(page).to have_no_selector('.notification-box')
      end
    end
  end
end
