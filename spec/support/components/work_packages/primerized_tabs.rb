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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Components
  module WorkPackages
    class PrimerizedTabs
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      # Check value of counter for the given tab
      def expect_counter(tab, count)
        expect(page).to have_test_selector("wp-details-tab-component--#{tab}-counter", text: count)
      end

      # Counter should not be displayed, if there are no relations or watchers
      def expect_no_counter(tab)
        expect(page).not_to have_test_selector("wp-details-tab-component--#{tab}-counter")
      end

      # Check that the given tab is shown in the tab bar
      def expect_tab(tab)
        expect(page).to have_test_selector("wp-details-tab-component--tab-#{tab.downcase}")
      end

      # Tab should not be displayed, e.g. because the user lacks the permission
      def expect_no_tab(tab)
        expect(page).not_to have_test_selector("wp-details-tab-component--tab-#{tab.downcase}")
      end
    end
  end
end
