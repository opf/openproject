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
    class Baseline
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def expect_active
        expect(page).to have_css(".wp-table--baseline-th")
      end

      def expect_legends
        expect(page).to have_css(".op-baseline-legends")
      end

      def expect_legend_text(text)
        expect(page).to have_css(".op-baseline-legends--filter", text:)
      end

      def expect_legend_tooltip(text)
        expect(page).to have_css('[data-test-selector="baseline-legend-time-offset"]', visible: :all) { |node|
          node["title"] == text
        }
      end

      def expect_no_legends
        expect(page).to have_no_css(".op-baseline-legends")
      end

      def expect_inactive
        expect(page).to have_no_css(".wp-table--baseline-th")
        expect(page).to have_no_css(".op-table-baseline--column-cell")
      end

      def expect_changed(work_package)
        expect_icon(work_package, :changed)
      end

      def expect_added(work_package)
        expect_icon(work_package, :added)
      end

      def expect_removed(work_package)
        expect_icon(work_package, :removed)
      end

      def expect_unchanged(work_package)
        page.within(row_selector(work_package)) do
          expect(page).to have_no_css(".op-table-baseline--column-cell *")
        end
      end

      def expect_icon(work_package, icon_type)
        page.within(row_selector(work_package)) do
          expect(page).to have_css(".op-table-baseline--icon-#{icon_type}")
        end
      end

      def expect_changed_attributes(work_package, **changes)
        page.within(row_selector(work_package)) do
          changes.each do |attribute, (old_value, new_value)|
            base_selector = ".op-table-baseline--container.#{attribute}"
            expect(page).to have_css("#{base_selector} .op-table-baseline--old-field", text: old_value)

            if new_value == ""
              expect(page).to have_css("#{base_selector} .op-table-baseline--new-field", text: "", visible: :all)
            else
              expect(page).to have_css("#{base_selector} .op-table-baseline--new-field", text: new_value)
            end
          end
        end
      end

      def expect_unchanged_attributes(work_package, *changes)
        page.within(row_selector(work_package)) do
          changes.each do |attribute|
            expect(page).to have_no_css(".#{attribute}.op-table-baseline--old-field")
          end
        end
      end

      def row_selector(elem)
        id = elem.is_a?(WorkPackage) ? elem.id.to_s : elem.to_s
        ".wp-row-#{id}-table"
      end
    end
  end
end
