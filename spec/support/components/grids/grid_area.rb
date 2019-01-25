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
        area.find('.resizer').drag_to self.class.of(row, column).area
      end

      def remove
        area.find('.grid--widget-remove').click
      end

      def drag_to(row, column)
        handle = area.find('.cdk-drag-handle')
        drop_area = self.class.of(row, column).area

        # This weird combination of events is what works for no discernible reason
        page.driver.browser.action.click_and_hold(handle.native).perform
        sleep(0.3)
        drop_area.hover
        page.driver.browser.send(:bridge).mouse_move_to(drop_area)
        sleep(0.3)
        page.driver.browser.action.release(drop_area.native).perform
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        sleep(0.3)
        page.driver.browser.action.release(drop_area.native).perform
      end

      def expect_to_exist
        expect(page)
          .to have_selector(*area_selector)
      end

      def expect_to_span(startRow, startColumn, endRow, endColumn)
        [['grid-row-start', startRow],
         ['grid-column-start', startColumn],
         ['grid-row-end', endRow],
         ['grid-column-end', endColumn]].each do |style, expected_value|

          expect(area.native.style(style))
            .to eql(expected_value.to_s)
        end
      end

      def area
        page.find(*area_selector)
      end

      def self.of(row_number, column_number)
        area_style = "grid-area: #{row_number} / #{column_number} / #{row_number + 1} / #{column_number + 1}"

        new(".grid--area:not(-widgeted)[style*='#{area_style}']")
      end
    end
  end
end
