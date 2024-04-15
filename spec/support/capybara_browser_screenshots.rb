# frozen_string_literal: true

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
