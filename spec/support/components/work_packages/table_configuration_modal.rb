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
    class TableConfigurationModal
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def self.do_and_save
        new.tap do |modal|
          yield modal
          modal.save
        end
      end

      def open_and_switch_to(name)
        open!
        switch_to(name)
      end

      def open_and_set_display_mode(mode)
        open_and_switch_to 'Display settings'
        choose("display_mode_switch", option: mode)
      end

      def open!
        scroll_to_and_click trigger
        expect_open
      end

      def set_display_sums(enable: true)
        open_and_switch_to 'Display settings'

        if enable
          check 'display_sums_switch'
        else
          uncheck 'display_sums_switch'
        end
        save
      end

      def save
        find("#{selector} .button.-highlight").click
      end

      def cancel
        find("#{selector} .button", text: 'Cancel').click
      end

      def expect_open
        expect(page).to have_selector(selector, wait: 40)
      end

      def expect_closed
        expect(page).to have_no_selector(selector)
      end

      def expect_disabled_tab(name)
        expect(page).to have_selector("#{selector} .tab-show.-disabled", text: name)
      end

      def switch_to(target)
        find("#{selector} .tab-show", text: target).click
      end

      def selector
        '.wp-table--configuration-modal'
      end

      private

      def trigger
        find('.wp-table--configuration-modal--trigger')
      end
    end
  end
end
