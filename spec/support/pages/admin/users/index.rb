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

require 'support/pages/page'

module Pages
  module Admin
    module Users
      class Index < ::Pages::Page
        def path
          "/users"
        end

        def expect_listed(*users)
          rows = page.all 'td.username'
          expect(rows.map(&:text)).to include(*users.map(&:login))
        end

        def expect_non_listed
          expect(page)
            .to have_no_selector('tr.user')

          expect(page)
            .to have_selector('tr.generic-table--empty-row', text: 'There is currently nothing to display.')
        end

        def expect_user_locked(user)
          expect(page)
            .to have_selector('tr.user.locked td.username', text: user.login)
        end

        def filter_by_status(value)
          select value, from: 'Status:'
          click_button 'Apply'
        end

        def filter_by_name(value)
          fill_in 'Name', with: value
          click_button 'Apply'
        end

        def clear_filters
          click_link 'Clear'
        end

        def order_by(key)
          within 'thead' do
            click_link key
          end
        end

        def lock_user(user)
          click_user_button(user, 'Lock permanently')
        end

        def activate_user(user)
          click_user_button(user, 'Activate')
        end

        def reset_failed_logins(user)
          click_user_button(user, 'Reset failed logins')
        end

        def unlock_user(user)
          click_user_button(user, 'Unlock')
        end

        def unlock_and_reset_user(user)
          click_user_button(user, 'Unlock and reset failed logins')
        end

        def click_user_button(user, text)
          within_user_row(user) do
            click_link text
          end
        end

        private

        def within_user_row(user)
          row = find('tr.user', text: user.login)
          within row do
            yield
          end
        end
      end
    end
  end
end
