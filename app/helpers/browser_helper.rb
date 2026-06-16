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

module BrowserHelper
  ##
  # Instead of defining what makes up a modern user,
  # only define those where we want to show a warning.
  #
  # Uses the +browser+ gem.
  def unsupported_browser?
    RequestStore.fetch(:unsupported_browser) do
      # Any version of IE
      return true if browser.ie?

      version = browser.version.to_i

      # Older versions behind last ESR FF
      return true if browser.firefox? && version < 101

      # Chrome/chromium based Edge based versions older than a year
      return true if browser.chromium_based? && version < 109

      # Older version of safari
      return true if browser.safari? && version < 16

      # Older version of non-chromium based Edge
      return true if browser.edge? && version < 109

      false
    end
  end

  ##
  # Browser specific classes for browser-specific fixes
  # or mobile detection
  def browser_specific_classes # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    [].tap do |classes|
      classes << "-browser-chrome" if browser.chrome? || browser.chromium_based?
      classes << "-browser-firefox" if browser.firefox?
      classes << "-browser-webkit" if browser.safari? || browser.epiphany?
      classes << "-browser-edge" if browser.edge?

      classes << "-browser-mobile" if browser.device.mobile?
      classes << "-browser-windows" if browser.platform.windows?
      classes << "-unsupported-browser" if unsupported_browser?
    end
  end
end
