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
  module WorkPackages
    class BaselineModal
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def toggle_drop_modal
        page.find('[data-test-selector="baseline-button"]').click
      end

      def expect_closed
        expect(page).to have_no_css("op-baseline")
      end

      def expect_open
        expect(page).to have_css("op-baseline")
        expect(page).to have_field("op-baseline-filter")
      end

      def expect_selected(option)
        expect(page).to have_select("op-baseline-filter", selected: option)
      end

      def expect_selected_time(value)
        expect(page).to have_field("op-baseline-time", with: value)
      end

      def expect_no_time_field
        expect(page).to have_no_field("op-baseline-time")
      end

      def select_filter(option)
        page.select(option, from: "op-baseline-filter")
        expect_selected(option)
      end

      def expect_offset(value, count: 1)
        expect(page).to have_css(".op-baseline--time-help", text: value, count:)
      end

      def expect_time_help_text(text)
        expect(page).to have_css(".spot-form-field--description", text:)
      end

      def set_time(value, selector = "op-baseline-time")
        page.execute_script <<~JS
          const el = document.getElementsByName('#{selector}')[0];
          el.value = '#{value}';
          el.dispatchEvent(new Event('change'));
        JS
      end

      def set_date(value)
        fill_in "op-baseline-date", with: value
      end

      def set_between_dates(from:, from_time:, to:, to_time:)
        fill_in "op-baseline-from-date", with: from
        sleep 0.5
        fill_in "op-baseline-to-date", with: to

        set_time from_time, "op-baseline-from-time"
        set_time to_time, "op-baseline-to-time"
      end

      def expect_between_dates(from:, from_time:, to:, to_time:)
        expect(page).to have_field("op-baseline-from-time", with: from_time)
        expect(page).to have_field("op-baseline-to-time", with: to_time)

        expect(page).to have_field("op-baseline-from-date", with: from)
        expect(page).to have_field("op-baseline-to-date", with: to)
      end

      def apply
        page.within("op-baseline") do
          click_button "Apply"
        end
      end
    end
  end
end
