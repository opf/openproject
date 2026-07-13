# frozen_string_literal: true

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
    class DestroyModal
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def initialize(bulk_mode: false)
        @bulk_mode = bulk_mode
      end

      def dialog_css_selector
        "dialog#wp-delete-dialog"
      end

      def within_dialog(&)
        within(dialog_css_selector, &)
      end

      def expect_listed(*work_packages)
        within_dialog do
          work_packages.each do |work_package|
            expect(page).to have_text(work_package.subject)
          end
        end
      end

      def confirm_deletion
        within_dialog do
          check "I understand that this deletion cannot be reversed"
          expect(page).to have_button "Delete permanently", disabled: false
          click_button "Delete permanently"
        end
      end

      def cancel_deletion
        within_dialog do
          click_button "Cancel"
        end
      end
    end
  end
end
