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

require "capybara-screenshot"
require "capybara-screenshot/rspec"

# Remove old images automatically
Capybara::Screenshot.prune_strategy = :keep_last_run

# Set up S3 uploads if desired
if ENV["CAPYBARA_AWS_ACCESS_KEY_ID"].present?
  Capybara::Screenshot.s3_configuration = {
    s3_client_credentials: {
      access_key_id: ENV.fetch("CAPYBARA_AWS_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("CAPYBARA_AWS_SECRET_ACCESS_KEY"),
      region: ENV.fetch("CAPYBARA_AWS_REGION", "eu-west-1")
    },
    bucket_name: ENV.fetch("CAPYBARA_AWS_BUCKET", "openproject-ci-public-logs")
  }
  Capybara::Screenshot.s3_object_configuration = {
    acl: "public-read"
  }
end

class Capybara::ScreenshotAdditions
  class Formatter
    RSpec::Core::Formatters.register(
      self,
      :example_failed
    )

    attr_reader :output

    def initialize(output)
      @output = output
    end

    def example_failed(notification)
      output_screenshot_info(notification.example)
    end

    private

    def output_screenshot_info(example)
      return unless screenshot = example.metadata[:screenshot]

      info = {
        message: "Screenshot captured for failed feature test",
        test_id: example.id,
        test_location: example.location
      }.merge(screenshot)

      output.puts("\n#{info.to_json}")
    end
  end

  def self.report_screenshots?(formatter)
    formatter.singleton_class.include?(Capybara::Screenshot::RSpec::TextReporter)
  end
end

# Add a custom formatter to output screenshot information if there are no
# formatters patched by capybara-screenshot. This can happen with turbo_tests
# which uses custom formatters not supported by capybara-screenshot.
RSpec.configure do |config|
  config.before(:suite) do
    if config.formatters.none? { |formatter| Capybara::ScreenshotAdditions.report_screenshots?(formatter) }
      config.add_formatter(Capybara::ScreenshotAdditions::Formatter)
    end
  end
end
