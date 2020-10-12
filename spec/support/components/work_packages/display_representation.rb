#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  module WorkPackages
    class DisplayRepresentation
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def switch_to_card_layout
        expect_button 'Card'
        select_view 'Card'
      end

      def switch_to_list_layout
        expect_button 'Table'
        select_view 'Table'
        end

      def switch_to_gantt_layout
        expect_button 'Gantt'
        select_view 'Gantt'
      end

      def expect_state(text)
        expect(page).to have_selector('#wp-view-toggle-button', text: text, wait: 10)
      end

      private

      def expect_button(forbidden_text)
        expect(page).to have_button('wp-view-toggle-button', disabled: false)
        expect(page).to have_no_selector('#wp-view-toggle-button', text: forbidden_text)
      end

      def select_view(view_name)
        page.find('wp-view-toggle-button').click

        within_view_context_menu do
          click_link(view_name)
        end
      end

      def within_view_context_menu
        page.within('#wp-view-context-menu') do
          yield
        end
      end
    end
  end
end
