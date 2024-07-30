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

# Customize browser download path until https://github.com/rubycdp/cuprite/pull/217 is released.
module SetCupriteDownloadPath
  def initialize(app, options = {})
    super
    @options[:save_path] = DownloadList::SHARED_PATH.to_s
  end
end
Capybara::Cuprite::Driver.prepend(SetCupriteDownloadPath)

def register_better_cuprite(language, name: :"better_cuprite_#{language}")
  Capybara.register_driver(name) do |app|
    options = {
      process_timeout: 20,
      timeout: 10,
      # In case the timeout is not enough, this option can be activated:
      # pending_connection_errors: false,
      inspector: true,
      headless: headless_mode?,
      window_size: [1920, 1080]
    }

    if headful_mode? && ENV["CAPYBARA_WINDOW_RESOLUTION"]
      window_size = WindowResolutionManagement.extract_dimensions(ENV["CAPYBARA_WINDOW_RESOLUTION"])
      options = options.merge(window_size:)
    end

    if headful_mode? && ENV["OPENPROJECT_TESTING_SLOWDOWN_FACTOR"]
      options = options.merge(slowmo: ENV["OPENPROJECT_TESTING_SLOWDOWN_FACTOR"])
    end

    if ENV["CHROME_URL"].present?
      options = options.merge(url: ENV["CHROME_URL"])
    end

    browser_options = {
      "disable-dev-shm-usage": nil,
      "disable-gpu": nil,
      "disable-popup-blocking": nil,
      lang: language,
      "no-sandbox": nil,
      "disable-smooth-scrolling": true
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

register_better_cuprite "en"

MODULES_WITH_CUPRITE_ENABLED = %w[
  avatars
  backlogs
  job_status
  meeting
].freeze

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/(#{MODULES_WITH_CUPRITE_ENABLED.join('|')})/spec/features/}) do |meta|
    if meta[:js] && !meta.key?(:with_cuprite)
      meta[:with_cuprite] = true
    end
  end

  config.around(:each, :with_cuprite, type: :feature) do |example|
    original_driver = Capybara.javascript_driver
    begin
      Capybara.javascript_driver = :better_cuprite_en
      example.run
    ensure
      Capybara.javascript_driver = original_driver
    end
  end
end
