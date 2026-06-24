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

require "capybara/cuprite"

module CupriteCdpLogger
  class << self
    attr_accessor :logger
  end
end

def headful_mode?
  ActiveRecord::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_TESTING_NO_HEADLESS", nil))
end

def headless_mode?
  !headful_mode?
end

module WindowResolutionManagement
  DIMENSION_SEPARATOR = "x"

  class << self
    # @param [String] resolution, "1920x1080"
    # @return [Array<Int,Int>] width and height representation of the resolution, [1920, 1080]
    def extract_dimensions(resolution)
      resolution.downcase
                .split(DIMENSION_SEPARATOR)
                .map(&:to_i)
    end
  end
end

def register_better_cuprite(language, name: :"better_cuprite_#{language}")
  Capybara.register_driver(name) do |app|
    options = {
      process_timeout: 20,
      timeout: 10,
      # In case the timeout is not enough, this option can be activated:
      # pending_connection_errors: false,
      inspector: true,
      headless: headless_mode?,
      save_path: DownloadList::SHARED_PATH.to_s,
      window_size: [1920, 1080],
      # workaround for compatibility issues with browserless docker image and ferrum
      # see https://github.com/rubycdp/ferrum/issues/540
      flatten: false
    }

    if headful_mode? && ENV["CAPYBARA_WINDOW_RESOLUTION"]
      window_size = WindowResolutionManagement.extract_dimensions(ENV["CAPYBARA_WINDOW_RESOLUTION"])
      options = options.merge(window_size:)
    end

    if headful_mode? && ENV["OPENPROJECT_TESTING_SLOWDOWN_FACTOR"]
      options = options.merge(slowmo: ENV["OPENPROJECT_TESTING_SLOWDOWN_FACTOR"])
    end

    options = configure_remote_chrome(options)

    CupriteCdpLogger.logger = StringIO.new
    options = options.merge(logger: CupriteCdpLogger.logger)

    browser_options = {
      "disable-dev-shm-usage": nil,
      "disable-gpu": nil,
      "disable-popup-blocking": nil,
      lang: language,
      "accept-lang": language,
      "no-sandbox": nil,
      "disable-smooth-scrolling": true,
      # Disable timers being throttled in background pages/tabs. Useful for
      # parallel test runs.
      "disable-background-timer-throttling": nil,
      # Normally, Chrome will treat a 'foreground' tab instead as backgrounded
      # if the surrounding window is occluded (aka visually covered) by another
      # window. This flag disables that. Useful for parallel test runs.
      "disable-backgrounding-occluded-windows": nil,
      # This disables non-foreground tabs from getting a lower process priority.
      # Useful for parallel test runs.
      "disable-renderer-backgrounding": nil,
      # Software GPU to avoid the dreaded "[ERROR] [Canvas '__0']: Failed to get a
      # WebGL context" error for tests using xeokit. The automatic fallback to SwiftShader
      # was disabled in January 2026, so that we now have to enable the fallback manually in
      # the test environment.
      # See https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/gpu/swiftshader.md
      "use-gl": "angle",
      "use-angle": "swiftshader-webgl",
      "enable-unsafe-swiftshader": true
    }

    if ENV["OPENPROJECT_TESTING_AUTO_DEVTOOLS"].present?
      browser_options = browser_options.merge("auto-open-devtools-for-tabs": nil)
    end

    driver_options = options.merge(browser_options:)

    Capybara::Cuprite::Driver.new(app, **driver_options)
  end

  Capybara::Screenshot.register_driver(name) do |driver, path|
    driver.save_screenshot(path)
  end
end

def configure_remote_chrome(options)
  if ENV["CHROME_URL"].present? && ENV["CHROME_WS_URL"].present?
    raise "Both CHROME_URL and CHROME_WS_URL were passed. Only one can be accepted at a time."
  end

  return options.merge(url: ENV["CHROME_URL"]) if ENV["CHROME_URL"].present?
  return options.merge(ws_url: ENV["CHROME_WS_URL"]) if ENV["CHROME_WS_URL"].present?

  options
end

# Ferrum v0.17.2 regression: https://github.com/rubycdp/ferrum/issues/578
Ferrum::Contexts.prepend(Module.new do
  def reset
    super
    @default_context = nil
  end

  private

  def add_context(context_id)
    return if contexts[context_id]

    context = Ferrum::Context.new(@client, self, context_id)
    contexts[context_id] = context
  end
end)

register_better_cuprite "en"

RSpec.configure do |config|
  config.around(:each, :js, type: :feature) do |example|
    # Skip if driver is explicitly requested
    if example.metadata[:driver]
      example.run
      next
    end

    original_driver = Capybara.javascript_driver

    begin
      Capybara.javascript_driver =
        if example.metadata[:selenium]
          :chrome_en
        else
          :better_cuprite_en
        end

      example.run
    ensure
      Capybara.javascript_driver = original_driver
    end
  end
end
