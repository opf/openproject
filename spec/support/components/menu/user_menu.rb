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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Components
  class UserMenu
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def open
      page.find_test_selector("op-app-header--user-menu-button").click
    end

    def close
      page.find(".op-app-header--modules-menu-header .close-button").click
    end

    def expect_user_shown(user_name)
      page.within_test_selector "op-app-header--user-menu-button" do
        expect(page).to have_element "data-title": "\"#{user_name}\""
      end
    end
  end
end
