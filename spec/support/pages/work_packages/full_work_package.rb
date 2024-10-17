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

require "support/pages/work_packages/abstract_work_package"

module Pages
  class FullWorkPackage < Pages::AbstractWorkPackage
    def ensure_loaded
      find(".work-packages--details--subject", match: :first)
    end

    def toolbar
      find_by_id("toolbar-items")
    end

    def click_share_button
      within toolbar do
        # The request to the capabilities endpoint determines
        # whether the "Share" button is rendered or not.
        # Instead of waiting for an idle network (which may
        # include waiting for other network requests unrelated to
        # sharing), waiting for the button to be present makes
        # the spec a tad faster.
        click_button("Share", wait: 10)
      end
    end

    def expect_share_button_count(count)
      page.within_test_selector("op-wp-share-button") do
        expect(page).to have_css(".badge", text: count, wait: 10)
      end
    end

    def wait_for_activity_tab
      expect(page).to have_test_selector("op-wp-activity-tab", wait: 10)
      # wait for stimulus js component to be mounted
      expect(page).to have_css('[data-test-selector="op-wp-activity-tab"][data-stimulus-controller-connected="true"]')
    end

    private

    def container
      find(".work-packages--show-view")
    end

    def path(tab = "activity")
      if project
        project_work_package_path(project, work_package.id, tab)
      else
        work_package_path(work_package.id, tab)
      end
    end

    def create_page(args)
      Pages::FullWorkPackageCreate.new(**args)
    end
  end
end
