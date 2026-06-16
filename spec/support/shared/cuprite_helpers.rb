# frozen_string_literal: true

# -- copyright
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
# ++
#

# Wrapper for Cuprite's `page.driver.wait_for_network_idle`
# Used to wait for Network traffic to become idle, helping
# in specs where AJAX requests are performed by angular components.
# This is especially helpful as it doesn't depend on DOM elements
# being present or gone. Instead the execution is halted until
# requested data is done being fetched.
def wait_for_network_idle(...)
  if using_cuprite?
    page.driver.wait_for_network_idle(...)
  else
    warn_about_cuprite_helper_misuse(:wait_for_network_idle)
  end
end

# Takes the above `wait_for_network_idle` a step further by waiting
# for the page to be reloaded after some triggering action.
def wait_for_reload
  if using_cuprite?
    page.driver.wait_for_reload
  else
    warn_about_cuprite_helper_misuse(:wait_for_reload)
  end
end

def warn_about_cuprite_helper_misuse(method_name)
  # Don't bloat the output of the CI
  return if ENV["CI"]

  stack = caller(2)
  cause = [stack[0], stack.find { |line| line["_spec.rb:"] }].uniq.join(" … ")
  warn "#{method_name} used in spec not using cuprite (#{cause})"
end

# Ferrum is yet support `fill_options` as a Hash
def clear_input_field_contents(input_element)
  if input_element.is_a? String
    input_element = find_field(input_element)
  end

  return unless input_element.value.length.positive?

  # Move to the end of the input field and then backspace to clear the field.
  rights = Array.new(input_element.value.length, :right)
  backspaces = Array.new(input_element.value.length, :backspace)
  input_element.native.node.type(*rights)
  input_element.native.node.type(*backspaces)
end

# Executes the given block and waits for a Turbo stream to be rendered.
#
# Sets up a JS event listener BEFORE yielding, avoiding the race condition
# where the stream renders before the listener is registered.
#
# @example
#   wait_for_turbo_stream { click_button "Save" }
#   expect(page).to have_text("Saved")
#
def wait_for_turbo_stream(wait: 10, &block)
  unless using_cuprite?
    yield if block
    return
  end

  unless wait
    yield if block
    return
  end

  timeout = wait == true ? 10 : wait
  timeout_ms = timeout * 1000
  page.execute_script(<<~JS, timeout_ms)
    window.__opTurboStreamRendered = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('wait_for_turbo_stream: no turbo stream rendered within #{timeout}s')), arguments[0]);
      document.addEventListener('op:turbo-stream-rendered', () => { clearTimeout(timer); resolve(true); }, { once: true });
    });
  JS

  yield

  result = page.driver.evaluate_async_script(<<~JS)
    window.__opTurboStreamRendered.then(() => {
      delete window.__opTurboStreamRendered;
      arguments[0]({ success: true });
    }).catch((e) => {
      delete window.__opTurboStreamRendered;
      arguments[0]({ success: false, error: e.message });
    });
  JS

  raise result["error"] if result.is_a?(Hash) && !result["success"]
end

# Executes the given block and waits for a Turbo Drive navigation to complete.
#
# Sets up a listener for turbo:load BEFORE yielding, avoiding the race
# condition where the navigation completes before the listener is registered.
#
# @example
#   wait_for_turbo { click_link_or_button "Save" }
#   expect(page).to have_text("Saved")
#
def wait_for_turbo(wait: 10, &block)
  unless using_cuprite?
    yield if block
    return
  end

  unless wait
    yield if block
    return
  end

  timeout = wait == true ? 10 : wait
  timeout_ms = timeout * 1000
  page.execute_script(<<~JS, timeout_ms)
    window.__opTurboLoaded = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('wait_for_turbo: no turbo:load event within #{timeout}s')), arguments[0]);
      document.addEventListener('turbo:load', () => { clearTimeout(timer); resolve(true); }, { once: true });
    });
  JS

  yield

  result = page.driver.evaluate_async_script(<<~JS)
    window.__opTurboLoaded.then(() => {
      delete window.__opTurboLoaded;
      arguments[0]({ success: true });
    }).catch((e) => {
      delete window.__opTurboLoaded;
      arguments[0]({ success: false, error: e.message });
    });
  JS

  raise result["error"] if result.is_a?(Hash) && !result["success"]
end

# Executes the given block and waits for a Turbo frame navigation to complete.
#
# Sets up a listener for turbo:frame-load BEFORE yielding, avoiding the race
# condition where the frame loads before the listener is registered.
#
# @example
#   wait_for_turbo_frame { click_link "Remove column" }
#   expect(page).to have_text("Updated")
#
def wait_for_turbo_frame(wait: 10, &block)
  unless using_cuprite?
    yield if block
    return
  end

  unless wait
    yield if block
    return
  end

  timeout = wait == true ? 10 : wait
  timeout_ms = timeout * 1000
  page.execute_script(<<~JS, timeout_ms)
    window.__opTurboFrameLoaded = new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('wait_for_turbo_frame: no turbo:frame-load event within #{timeout}s')), arguments[0]);
      document.addEventListener('turbo:frame-load', () => { clearTimeout(timer); resolve(true); }, { once: true });
    });
  JS

  yield

  result = page.driver.evaluate_async_script(<<~JS)
    window.__opTurboFrameLoaded.then(() => {
      delete window.__opTurboFrameLoaded;
      arguments[0]({ success: true });
    }).catch((e) => {
      delete window.__opTurboFrameLoaded;
      arguments[0]({ success: false, error: e.message });
    });
  JS

  raise result["error"] if result.is_a?(Hash) && !result["success"]
end

# Waits for CKEditor to be fully initialized.
#
# CKEditor is an Angular component (`opce-ckeditor-augmented-textarea`)
# that initializes asynchronously after its container is inserted into the DOM
# (e.g. via a Turbo Stream). The `.ck-content` element only appears once the
# editor instance is fully created, so waiting for it is a reliable readiness signal.
#
# Uses a generous timeout because Angular bootstrap + CKEditor init can be slow on CI.
#
# @example
#   wait_for_turbo_stream { description_field.open_field }
#   wait_for_ckeditor
#   wait_for_turbo_stream { description_field.fill_and_submit_value(...) }
#
def wait_for_ckeditor(wait: 20)
  expect(page).to have_css(".ck-content", wait:)
end

def using_cuprite?
  Capybara.javascript_driver == :better_cuprite_en
end
