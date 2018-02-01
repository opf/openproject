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
    class SettingsMenu
      include Capybara::DSL
      include RSpec::Matchers

      def open_and_save_query(name)
        open!
        find("#{selector} .menu-item", text: 'Save', match: :prefer_exact).click
        page.within('.ng-modal-inner') do
          find('#save-query-name').set name
          click_on 'Save'
        end
      end

      def open_and_choose(name)
        open!
        choose(name)
      end

      def open!
        click_on 'work-packages-settings-button'
        expect_open
      end

      def expect_open
        expect(page).to have_selector(selector)
      end

      def expect_closed
        expect(page).to have_no_selector(selector)
      end

      def choose(target)
        find("#{selector} .menu-item", text: target).click
      end

      def expect_options(options)
        expect_open
        options.each do |text|
          expect(page).to have_selector("#{selector} a", text: text)
        end
      end

      private

      def selector
        '#settingsDropdown'
      end
    end
  end
end
