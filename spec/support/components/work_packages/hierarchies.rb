#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Components
  module WorkPackages
    class Hierarchies
      include Capybara::DSL
      include RSpec::Matchers

      def enable_hierarchy
        find('#work-packages-settings-button').click
        page.find('#settingsDropdown a.menu-item', text: 'Display hierarchy').click
      end

      def disable_hierarchy
        find('#work-packages-settings-button').click
        expect(page).to have_selector('#settingsDropdown .menu-item')
        page.find('#settingsDropdown a.menu-item', text: 'Hide hierarchy').click
      end

      def expect_no_hierarchies
        expect(page).to have_no_selector('.wp-table--hierarchy-span')
      end

      def expect_leaf_at(*work_packages)
        work_packages.each do |wp|
          expect(page).to have_selector(".wp-row-#{wp.id} .wp-table--leaf-indicator")
        end
      end

      def expect_hierarchy_at(*work_packages, collapsed: false)
        collapsed_sel = ".-hierarchy-collapsed"

        work_packages.each do |wp|
          selector = ".wp-row-#{wp.id} .wp-table--hierarchy-indicator"

          if collapsed
            expect(page).to have_selector("#{selector}#{collapsed_sel}")
          else
            expect(page).to have_selector(selector)
            expect(page).to have_no_selector("#{selector}#{collapsed_sel}")
          end
        end
      end

      def expect_hidden(*work_packages)
        work_packages.each do |wp|
          expect(page).to have_selector(".wp-row-#{wp.id}", visible: :hidden)
        end
      end

      def toggle_row(work_package)
        find(".wp-row-#{work_package.id} .wp-table--hierarchy-indicator").click
      end
    end
  end
end
