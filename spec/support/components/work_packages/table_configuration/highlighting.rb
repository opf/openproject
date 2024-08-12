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
    class Highlighting
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def switch_highlighting_mode(label)
        modal_open? or open_modal
        choose label

        apply
      end

      def switch_entire_row_highlight(label)
        modal_open? or open_modal
        choose "Entire row by"

        # Open select field
        within(page.all(".form--field")[1]) do
          page.find(".ng-input input").click
        end
        page.find(".ng-dropdown-panel .ng-option", text: label).click
        apply
      end

      def switch_inline_attribute_highlight(*labels)
        modal_open? or open_modal
        choose "Highlighted attribute(s)"

        # Open select field
        within(page.all(".form--field")[0]) do
          page.find(".ng-input input").click
        end

        # Delete all previously selected options
        page.all(".ng-dropdown-panel .ng-option-selected").each { |option| option.click }

        labels.each do |label|
          page.find(".ng-dropdown-panel .ng-option", text: label).click
        end

        apply
      end

      def apply
        @opened = false

        click_button("Apply")
      end

      def open_modal
        @opened = true
        ::Components::WorkPackages::SettingsMenu.new.open_and_choose "Configure view"

        retry_block do
          find(".op-tab-row--link", text: "HIGHLIGHTING", wait: 10).click
        end
      end

      def assume_opened
        @opened = true
      end

      private

      def within_modal(&)
        page.within(".wp-table--configuration-modal", &)
      end

      def modal_open?
        !!@opened
      end
    end
  end
end
