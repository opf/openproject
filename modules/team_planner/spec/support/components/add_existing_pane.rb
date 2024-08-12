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
  class AddExistingPane
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def selector
      "[data-test-selector='add-existing-pane']"
    end

    def open
      page.find('[data-test-selector="op-team-planner--add-existing-toggle"]').click
      expect_open
    end

    def expect_open
      expect(page).to have_selector(selector)
    end

    def expect_closed
      expect(page).to have_no_selector(selector)
    end

    def expect_empty
      expect(page).to have_css("[data-test-selector='op-add-existing-pane--empty-state']")
    end

    def search(term)
      page.find("[data-test-selector='op-add-existing-pane--search-input'] input").set(term)
    end

    def expect_result(work_package, visible: true)
      if visible
        expect(page)
          .to have_css("[data-test-selector='op-add-existing-pane--wp-#{work_package.id}']", wait: 10)
      else
        expect(page)
          .to have_no_css("[data-test-selector='op-add-existing-pane--wp-#{work_package.id}']")
      end
    end

    def drag_wp_by_pixel(work_package, by_x, by_y)
      source = page
                 .find("[data-test-selector='op-add-existing-pane--wp-#{work_package.id}']")

      drag_by_pixel(element: source, by_x:, by_y:)
    end

    def card(work_package)
      page.find(".op-wp-single-card-#{work_package.id}")
    end
  end
end
