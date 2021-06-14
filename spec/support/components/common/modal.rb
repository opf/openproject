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
  module Common
    class Modal
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def expect_title(text)
        within_modal do
          expect(page).to have_selector('.op-modal--title' ,text: text)
        end
      end

      def expect_open
        expect(page).to have_selector(selector, wait: 40)
      end

      def expect_closed
        expect(page).to have_no_selector(selector)
      end

      def expect_text(text)
        within_modal do
          expect(page).to have_text(text)
        end
      end

      def click_modal_button(text)
        within_modal do
          click_button text
        end
      end

      def within_modal(&block)
        page.within(selector, &block)
      end

      def modal_element
        page.find(selector)
      end

      def selector
        '.op-modal'
      end
    end
  end
end
