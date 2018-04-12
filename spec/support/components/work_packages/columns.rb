#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
    class Columns
      include Capybara::DSL
      include RSpec::Matchers

      def expect_column_available(name)
        modal_open? or open_modal

        within_modal do
          page.find('#selected_columns').click

          expect(page)
            .to have_selector('li[role=option]', text: name)
        end
      end

      def expect_column_not_available(name)
        modal_open? or open_modal

        within_modal do
          expect(page)
            .to have_no_selector('.form--check-box-container', text: name)
        end
      end

      def add(name)
        modal_open? or open_modal

        within_modal do
          input = find "input[type=checkbox][title='#{name}'"
          input.set true
        end

        apply
      end

      def remove(name)
        modal_open? or open_modal

        within_modal do
          input = find "input[type=checkbox][title='#{name}'"
          input.set false
        end

        apply
      end

      def apply
        @opened = false

        click_button('Apply')
      end

      def open_modal
        @opened = true
        ::Components::WorkPackages::TableConfigurationModal.new.open_and_switch_to 'Columns'
      end

      private

      def within_modal
        page.within('.wp-table--configuration-modal') do
          yield
        end
      end

      def modal_open?
        !!@opened
      end
    end
  end
end
