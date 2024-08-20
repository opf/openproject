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

require_relative "split_work_package"

module Pages
  class PrimerizedSplitWorkPackage < Pages::SplitWorkPackage
    def in_split_view(&)
      page.within("#work-package-details-#{work_package.id}", &)
    end

    def switch_to_tab(tab:)
      in_split_view do
        page.find_test_selector(tab_selector(tab)).click
      end
    end

    def switch_to_fullscreen
      page.find_test_selector("wp-details-tab-component--full-screen").click
      FullWorkPackage.new(work_package, project)
    end

    def close
      page.find_test_selector("wp-details-tab-component--close").click
    end

    def expect_tab(tab)
      within_test_selector(tab_selector(tab)) do |link|
        link["data-aria-current"] == "page"
      end
    end

    def within_active_tab(&)
      within(".work-packages--details-content", &)
    end

    def path(tab = "overview")
      details_notifications_path(work_package.id, tab:)
    end

    private

    def tab_selector(tab)
      "wp-details-tab-component--tab-#{tab.downcase}"
    end
  end
end
