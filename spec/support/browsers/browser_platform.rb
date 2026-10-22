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

# The modifier a page under test honours for multi-select: Cmd on an Apple
# platform, Ctrl elsewhere. The browser under test decides, since a grid can
# run it on another OS than this host.
module BrowserPlatform
  module_function

  def multi_select_modifier(session = Capybara.current_session)
    apple?(session) ? :meta : :control
  end

  def apple?(session = Capybara.current_session)
    platform_name(session).match?(/mac|darwin|ios/i)
  end

  # Selenium and Cuprite can both drive a browser on another machine; only
  # the latter has no platform capability, but its user agent names the OS.
  def platform_name(session)
    driver = session.driver
    reported =
      case driver
      when Capybara::Selenium::Driver then driver.browser.capabilities.platform_name
      when Capybara::Cuprite::Driver then driver.browser.version.user_agent
      end

    reported.presence || RbConfig::CONFIG["host_os"]
  end
end
