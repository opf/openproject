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
    class TimerButton
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def expect_active
        expect(page).to have_css('[data-test-selector="timer-active"]', wait: 10)
      end

      def expect_inactive
        expect(page).to have_css('[data-test-selector="timer-inactive"]', wait: 10)
      end

      def expect_time(text)
        expect(page).to have_css('[data-test-selector="timer-active"]', wait: 10, text:)
      end

      def expect_visible(visible: true)
        if visible
          expect(page).to have_css("op-wp-timer-button")
        else
          expect(page).to have_no_css("op-wp-timer-button")
        end
      end

      def start
        close_dropdown
        page.within("op-wp-timer-button") do
          find('[data-test-selector="timer-inactive"]').click
        end
      end

      def stop
        page.within("op-wp-timer-button") do
          find('[data-test-selector="timer-active"]').click
        end
      end

      # Fix to close active dropdowns in the top menu
      def close_dropdown
        page.evaluate_script <<~JS
          document
              .getElementById('wrapper')
              .dispatchEvent(new MouseEvent('click'))
        JS
      end
    end
  end
end
