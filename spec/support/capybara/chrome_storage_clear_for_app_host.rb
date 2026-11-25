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

require "capybara/selenium/driver"

# Chrome 158 rejects "*" as the origin of Storage.clearDataForOrigin, which Capybara 3.40
# sends at the end of every ChromeDriver#reset!. Remove once Capybara ships a fix.
# https://github.com/teamcapybara/capybara/issues/2865
module ChromeStorageClearForAppHost
  private

  def execute_cdp(cmd, params = {})
    if cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"
      super("Network.clearBrowserCookies")
      super(cmd, params.merge(origin: Capybara.app_host))
    else
      super
    end
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageClearForAppHost)
