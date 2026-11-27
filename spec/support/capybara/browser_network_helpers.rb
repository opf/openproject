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
module BrowserNetworkHelpers
  def tracking_websockets
    identifier = ferrum_browser.page.command(
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
    ferrum_browser.page.command("Page.removeScriptToEvaluateOnNewDocument", identifier:) if identifier
  end

  def while_network_cut
    network = ferrum_browser.network
    network.offline_mode
    close_tracked_websockets
    yield
  ensure
    network&.emulate_network_conditions(offline: false, latency: 0, download_throughput: -1, upload_throughput: -1)
  end

  def close_tracked_websockets
    closed = page.evaluate_script(<<~JS)
      (window.openSockets || []).map((socket) => socket.close()).length
    JS
    raise "No tracked WebSockets to close; was tracking_websockets active before the page loaded?" if closed.zero?
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

  def ferrum_browser
    raise "Network helpers need the Cuprite driver" unless using_cuprite?

    page.driver.browser
  end
end

RSpec.configure do |config|
  config.include BrowserNetworkHelpers, :js
end
