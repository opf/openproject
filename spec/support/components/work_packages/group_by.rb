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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  module WorkPackages
    class GroupBy
      include Capybara::DSL
      include RSpec::Matchers

      def enable_via_header(name)
        open_table_column_context_menu(name)

        within_column_context_menu do
          click_button('Group by')
        end
      end

      def enable_via_menu(name)
        modal = TableConfigurationModal.new

        modal.open_and_set_display_mode 'grouped'
        select name, from: 'selected_grouping'
        modal.save
      end

      def disable_via_menu
        modal = TableConfigurationModal.new
        modal.open_and_set_display_mode 'default'
        modal.save
      end

      def expect_number_of_groups(count)
        expect(page).to have_selector('[data-qa-selector="op-group--value"] .count', count: count)
      end

      def expect_grouped_by_value(value_name, count)
        expect(page).to have_selector('[data-qa-selector="op-group--value"]', text: "#{value_name} (#{count})")
      end

      def expect_no_groups
        expect(page).to have_no_selector('[data-qa-selector="op-group--value"]')
      end

      def expect_not_grouped_by(name)
        open_table_column_context_menu(name)

        within_column_context_menu do
          expect(page).to have_content('Group by')
        end
      end

      private

      def open_table_column_context_menu(name)
        page.find(".generic-table--sort-header ##{name.downcase}").click
      end

      def within_column_context_menu(&block)
        page.within('#column-context-menu', &block)
      end
    end
  end
end
