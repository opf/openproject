#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
    class ContextMenu
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def open_for(work_package, card_view: nil)
        # Close
        find('body').send_keys :escape
        sleep 0.5 unless using_cuprite?

        if card_view.nil?
          view_toggle_button = find_by_id('wp-view-toggle-button', wait: 0)
          # DEBUG Remove me
          if view_toggle_button.nil?
            puts "DEBUG: #{self}#open_for called for a page without a view toggle button. " \
                 "Example is #{RSpec.current_example.location} - #{RSpec.current_example.id}"
          end
          card_view = view_toggle_button&.text == 'Cards'
        end

        if card_view
          page.find(".op-wp-single-card-#{work_package.id}").right_click
        else
          page.find(".wp-row-#{work_package.id}-table").right_click
        end

        expect_open
      end

      def expect_open
        expect(page).to have_selector(selector)
      end

      def expect_closed
        expect(page).not_to have_selector(selector)
      end

      def choose(target)
        find("#{selector} .menu-item", text: target, exact_text: true).click
      end

      def expect_no_options(*options)
        expect_open
        options.each do |text|
          expect(page).not_to have_selector("#{selector} .menu-item", text:)
        end
      end

      def expect_options(options)
        expect_open
        options.each do |text|
          expect(page).to have_selector("#{selector} .menu-item", text:)
        end
      end

      private

      def selector
        '#work-package-context-menu'
      end
    end
  end
end
