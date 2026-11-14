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

# Emulated offline does not close WebSockets that are already open, so the helpers record sockets
# and close them when the network is cut.
module SeleniumNetworkHelpers
  def tracking_websockets
    identifier = chrome_devtools(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        window.openSockets = [];
        window.WebSocket = new Proxy(window.WebSocket, {
          construct(target, args) {
            const socket = new target(...args);
            window.openSockets.push(socket);
            return socket;
          }
        });
      JS
    ).fetch("identifier")
    yield
  ensure
    chrome_devtools("Page.removeScriptToEvaluateOnNewDocument", identifier:) if identifier
  end

  def while_network_cut
    emulate_network(offline: true)
    close_tracked_websockets
    yield
  ensure
    emulate_network(offline: false)
  end

  def close_tracked_websockets
    page.execute_script("(window.openSockets || []).forEach((socket) => socket.close());")
  end

  # Timers created before the block keep their real delay, so it must start after the page has loaded.
  def with_capped_timers(milliseconds = 250)
    page.execute_script(<<~JS, milliseconds)
      const cap = arguments[0];
      window.uncappedSetTimeout = window.setTimeout;
      window.setTimeout = (callback, delay, ...rest) =>
        window.uncappedSetTimeout(callback, Math.min(delay ?? 0, cap), ...rest);
    JS
    yield
  ensure
    page.execute_script(<<~JS)
      if (window.uncappedSetTimeout) {
        window.setTimeout = window.uncappedSetTimeout;
        delete window.uncappedSetTimeout;
      }
    JS
  end

  private

  def emulate_network(offline:)
    chrome_devtools("Network.enable")
    chrome_devtools("Network.emulateNetworkConditions",
                    offline:,
                    latency: 0,
                    downloadThroughput: offline ? 0 : -1,
                    uploadThroughput: offline ? 0 : -1)
  end

  def chrome_devtools(command, **params)
    driver = page.driver
    raise "Chrome DevTools helpers need the Selenium driver" unless driver.is_a?(Capybara::Selenium::Driver)

    driver.browser.execute_cdp(command, **params)
  end
end

RSpec.configure do |config|
  config.include SeleniumNetworkHelpers, :selenium
end
