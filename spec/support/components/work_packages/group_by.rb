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
    class GroupBy
      include Capybara::DSL
      include RSpec::Matchers

      def enable_via_header(name)
        open_table_column_context_menu(name)

        within_column_context_menu do
          click_link('Group by')
        end
      end

      def enable_via_menu(name)
        SettingsMenu.new.open_and_choose('Group by ...')

        select name, from: 'selected_columns_new'
        click_button 'Apply'
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

      def within_column_context_menu
        page.within('#column-context-menu') do
          yield
        end
      end
    end
  end
end
