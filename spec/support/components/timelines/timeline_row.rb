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
  module Timelines
    class TimelineRow
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      attr_reader :container

      def initialize(container)
        @container = container
      end

      def hover!
        @container.find(".timeline-element").hover
      end

      def expect_hovered_labels(left:, right:)
        hover!

        unless left.nil?
          expect(container).to have_css(".labelHoverLeft.not-empty", text: left)
        end
        unless right.nil?
          expect(container).to have_css(".labelHoverRight.not-empty", text: right)
        end

        expect(container).to have_css(".labelLeft", visible: false)
        expect(container).to have_css(".labelRight", visible: false)
        expect(container).to have_css(".labelFarRight", visible: false)
      end

      def expect_labels(left:, right:, farRight:)
        {
          labelLeft: left,
          labelRight: right,
          labelFarRight: farRight
        }.each do |className, text|
          if text.nil?
            expect(container).to have_css(".#{className}", visible: :all)
            expect(container).to have_no_css(".#{className}.not-empty", wait: 0)
          else
            expect(container).to have_css(".#{className}.not-empty", text:)
          end
        end
      end

      def hover_bar(offset_days: 0)
        wait_until_hoverable
        scrollToLeft
        offset_x = offset_days * 30
        page.driver.browser.action.move_to(@container.native, offset_x).perform
      end

      def click_bar(offset_days: 0)
        hover_bar(offset_days:)
        page.driver.browser.action.click.perform
      end

      def expect_hovered_bar(duration: 1)
        expected_length = duration * 30
        expect(container).to have_css('div[class^="__hl_background_"', style: { width: "#{expected_length}px" })
      end

      def expect_bar(duration: 1)
        loading_indicator_saveguard
        expected_length = duration * 30
        expect(container).to have_css(".timeline-element", style: { width: "#{expected_length}px" })
      end

      def expect_no_hovered_bar
        expect(container).to have_no_css('div[class^="__hl_background_"')
      end

      def expect_no_bar
        loading_indicator_saveguard
        expect(container).to have_no_css(".timeline-element")
      end

      def drag_and_drop(offset_days: 0, days: 1)
        wait_until_hoverable
        scrollToLeft
        offset_x_start = offset_days * 30
        start_dragging(container, offset_x: offset_x_start)
        offset_x = ((days - 1) * 30) + offset_x_start
        drag_element_to(container, offset_x:)
        drag_release
      end

      def wait_until_hoverable
        # The timeline element and the mouse handlers are lazily loaded and can
        # be hidden if no dates are set. Finding it waits until the lazy loading
        # has completed.
        container.find(".timeline-element", visible: :all)
      end

      private

      def scrollToLeft
        # timeline being scrolled to today is potentially moving elements of the tests out of sight
        # thus, let's scroll back timeline to the far left in order to restore ability to use e.g. "driver.move_to"
        page.driver.execute_script("document.getElementsByClassName('work-packages-tabletimeline--timeline-side')[0].scrollLeft=0")
      end
    end
  end
end
