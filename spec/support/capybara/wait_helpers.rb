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

module WaitHelpers
  # Wait for an element to stop being resized on the page
  #
  # Useful to wait for a primer dialog to finish opening, as they have an
  # opening animation.
  #
  # @param selector_or_element [String or Capybara::Node::Element] CSS selector or element to wait for
  # @param wait [Integer] Optional maximum time to wait in seconds, defaults to
  #   Capybara's default wait time
  def wait_for_size_animation_completion(selector_or_element, wait: Capybara.default_max_wait_time)
    element =
      case selector_or_element
      when String
        page.find(selector_or_element, wait:)
      when Capybara::Node::Element
        selector_or_element
      else
        raise ArgumentError, "Invalid selector or element"
      end
    page.document.synchronize do
      initial_position = page.evaluate_script("arguments[0].getBoundingClientRect()", element)
      sleep 0.1 # Small delay to allow for animation
      final_position = page.evaluate_script("arguments[0].getBoundingClientRect()", element)
      raise Capybara::ExpectationNotMet, "Animation not finished" unless initial_position == final_position
    end
  end

  # Executes the given block and waits for a Turbo Stream to be rendered.
  #
  # Registers a listener for `op:turbo-stream-rendered` BEFORE the block runs,
  # avoiding the race where the stream renders before the listener is attached.
  # Trigger the stream from inside the block.
  #
  # @example
  #   wait_for_turbo_stream { click_on "Save" }
  #   expect(page).to have_text("Saved")
  #
  # @param wait [Integer, true, false, nil] seconds to wait; +true+ uses
  #   Capybara's default wait time, a falsey value skips the wait and just runs the block
  # @yield the actions that trigger the Turbo Stream
  # @return [Object] the block's return value
  def wait_for_turbo_stream(wait: Capybara.default_max_wait_time, &)
    wait_for_browser_event("op:turbo-stream-rendered", wait:, &)
  end

  # Executes the given block and waits for a Turbo Drive navigation to complete.
  #
  # Registers a listener for `turbo:load` BEFORE the block runs, avoiding the
  # race where the navigation completes before the listener is attached.
  # Trigger the navigation from inside the block.
  #
  # @example
  #   wait_for_turbo { click_on "Save" }
  #   expect(page).to have_text("Saved")
  #
  # @param wait [Integer, true, false, nil] seconds to wait; +true+ uses
  #   Capybara's default wait time, a falsey value skips the wait and just runs the block
  # @yield the actions that trigger the navigation
  # @return [Object] the block's return value
  def wait_for_turbo(wait: Capybara.default_max_wait_time, &)
    wait_for_browser_event("turbo:load", wait:, &)
  end

  # Executes the given block and waits for a Turbo Frame navigation to complete.
  #
  # Registers a listener for `turbo:frame-load` BEFORE the block runs, avoiding
  # the race where the frame loads before the listener is attached. Trigger the
  # frame load from inside the block.
  #
  # @example
  #   wait_for_turbo_frame { click_on "Remove column" }
  #   wait_for_turbo_frame(frame: "backlogs_container") { drop_card }
  #
  # @param frame [String, Symbol, nil] when given, only a turbo:frame-load whose
  #   target element has this id satisfies the wait; otherwise the first frame
  #   load of any frame satisfies it
  # @param wait [Integer, true, false, nil] seconds to wait; +true+ uses
  #   Capybara's default wait time, a falsey value skips the wait and just runs the block
  # @yield the actions that trigger the frame load
  # @return [Object] the block's return value
  def wait_for_turbo_frame(frame: nil, wait: Capybara.default_max_wait_time, &)
    wait_for_browser_event("turbo:frame-load", target_id: frame&.to_s, wait:, &)
  end

  private

  # Shared implementation for the +wait_for_turbo*+ helpers.
  #
  # Registers a one-shot listener for +event_name+ before running the block,
  # then blocks until the event fires or raises on timeout. Driver-agnostic:
  # works under both Cuprite and Selenium.
  #
  # @param event_name [String] the DOM event to wait for
  # @param wait [Integer, true, false, nil] seconds to wait; +true+ uses
  #   Capybara's default wait time, a falsey value skips the wait and just runs the block
  # @param target_id [String, nil] when set, only an event whose target element
  #   has this id satisfies the wait
  # @yield the actions that trigger the event
  # @return [Object] the block's return value
  def wait_for_browser_event(event_name, wait: Capybara.default_max_wait_time, target_id: nil, &block)
    return block ? yield : nil unless wait

    timeout = wait == true ? Capybara.default_max_wait_time : wait
    description = target_id ? "'#{event_name}' on frame '#{target_id}'" : "'#{event_name}'"
    timeout_message = "Timed out after #{timeout}s waiting for #{description}"
    # A unique key per call keeps nested wait_for_turbo* calls from clobbering
    # each other's pending promise on the shared window registry.
    key = SecureRandom.hex(8)

    page.execute_script(<<~JS, key, event_name, timeout * 1000, target_id)
      const [key, eventName, timeoutMs, targetId] = arguments;
      (window.__opAwaitedBrowserEvents ||= {})[key] = new Promise((resolve, reject) => {
        const handler = (event) => {
          if (targetId && !(event.target instanceof Element && event.target.id === targetId)) { return; }
          clearTimeout(timer);
          document.removeEventListener(eventName, handler);
          resolve(true);
        };
        const timer = setTimeout(() => {
          document.removeEventListener(eventName, handler);
          reject(new Error(#{timeout_message.to_json}));
        }, timeoutMs);
        document.addEventListener(eventName, handler);
      });
      // Mark the promise handled so that, if the block raises before we await
      // it below, the eventual timeout rejection is not an unhandled rejection.
      window.__opAwaitedBrowserEvents[key].catch(() => {});
    JS

    block_result = yield

    result = page.evaluate_async_script(<<~JS, key)
      const key = arguments[0];
      const done = arguments[arguments.length - 1];
      window.__opAwaitedBrowserEvents[key].then(() => {
        delete window.__opAwaitedBrowserEvents[key];
        done({ success: true });
      }).catch((e) => {
        delete window.__opAwaitedBrowserEvents[key];
        done({ success: false, error: e.message });
      });
    JS

    raise result["error"] if result.is_a?(Hash) && !result["success"]

    block_result
  end
end

RSpec.configure do |config|
  config.include WaitHelpers, type: :feature
end
