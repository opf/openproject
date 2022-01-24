#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
    include RSpec::Matchers

    def initialize; end

    def selector
      "[data-qa-selector='add-existing-pane']"
    end

    def expect_open
      expect(page).to have_selector(selector)
    end

    def expect_closed
      expect(page).not_to have_selector(selector)
    end

    def expect_empty
      expect(page).to have_selector("[data-qa-selector='op-add-existing-pane--empty-state']")
    end

    def search(term)
      page.find("[data-qa-selector='op-add-existing-pane--search-input']").set(term)
    end

    def expect_result(work_package, visible: true)
      expect(page)
        .to have_conditional_selector(visible, "[data-qa-selector='op-add-existing-pane--wp-#{work_package.id}']")
    end

    def drag_wp_by_pixel(work_package, by_x, by_y)
      source = page
                 .find("[data-qa-selector='op-add-existing-pane--wp-#{work_package.id}']")

      drag_by_pixel(element: source, by_x: by_x, by_y: by_y)
    end
  end
end
