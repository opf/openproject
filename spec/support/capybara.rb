require 'socket'
require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'
require 'action_dispatch'

RSpec.shared_context 'with default_url_options and host name set to Capybara test server' do
  around do |example|
    original_host = default_url_options[:host]
    original_port = default_url_options[:port]
    original_host_setting = Setting.host_name
    default_url_options[:host] = Capybara.server_host
    default_url_options[:port] = Capybara.server_port
    Setting.host_name = "#{Capybara.server_host}:#{Capybara.server_port}"
    example.run
  ensure
    default_url_options[:host] = original_host
    default_url_options[:port] = original_port
    Setting.host_name = original_host_setting
  end
end

RSpec.configure do |config|
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :chrome_en

  port = ENV.fetch('CAPYBARA_SERVER_PORT', ParallelHelper.port_for_app).to_i
  if port > 0
    Capybara.server_port = port
  end
  Capybara.always_include_port = true

  if ENV['CAPYBARA_DYNAMIC_BIND_IP']
    ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
    hostname = ENV.fetch('CAPYBARA_APP_HOSTNAME', ip_address)
    Capybara.server_host = ip_address
    Capybara.app_host = "http://#{hostname}"
  else
    Capybara.server_host = ENV.fetch('CAPYBARA_APP_HOSTNAME', 'localhost')
  end

  # Set the default options
  config.include_context 'with default_url_options and host name set to Capybara test server', type: :feature

  # Make it possible to match on value attribute.
  #
  # For instance:
  #
  #     expect(page).to have_selector(".date input", value: "2022-11-17")
  #
  Capybara.modify_selector(:css) do
    filter(:value) { |node, v| node.value == v }
  end
end

##
# Configure capybara-screenshot

# Remove old images automatically
Capybara::Screenshot.prune_strategy = :keep_last_run

# silence puma if we're using it
Capybara.server = :puma, { Silent: false }

# Set up S3 uploads if desired
if ENV['CAPYBARA_AWS_ACCESS_KEY_ID']
  Capybara::Screenshot.s3_configuration = {
    s3_client_credentials: {
      access_key_id: ENV.fetch('CAPYBARA_AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('CAPYBARA_AWS_SECRET_ACCESS_KEY'),
      region: ENV.fetch('CAPYBARA_AWS_REGION', 'eu-west-1')
    },
    bucket_name: ENV.fetch('CAPYBARA_AWS_BUCKET', 'openproject-ci-public-logs')
  }
  Capybara::Screenshot.s3_object_configuration = {
    acl: 'public-read'
  }
end

Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end

# Capture browser logs on failed examples and output them in Progress and
# Documentation formatters.
module Capybara::CaptureBrowserLogs
  RSPEC_TEXT_FORMATTERS = [
    "RSpec::Core::Formatters::ProgressFormatter",
    "RSpec::Core::Formatters::DocumentationFormatter"
  ].freeze

  class << self
    def after_failed_example(example)
      return unless example.example_group.include?(Capybara::DSL)
      return unless failed?(example)
      return if Capybara.page.current_url.blank?
      return unless Capybara.page.driver.browser.respond_to?(:manage)

      logs = Capybara.page.driver.browser.manage.instance_variable_get(:@bridge).log("browser")
      example.metadata[:browser_logs] = logs
    rescue StandardError => e
      warn "Unable to get browser logs: #{e}"
    end

    def change_text_formatter_to_output_captured_browser_logs
      RSpec.configuration.formatters.each do |formatter|
        next unless RSPEC_TEXT_FORMATTERS.include?(formatter.class.to_s)
        next if formatter.singleton_class.included_modules.include?(TextReporter)

        formatter.singleton_class.prepend(TextReporter)
      end
    end

    def failed?(example)
      # reusing private method from capybara-screenshot gem
      Capybara::Screenshot::RSpec.send(:failed?, example)
    end
  end

  module TextReporter
    def example_failed(notification)
      super
      output_browser_logs(notification.example)
    end

    private

    def output_browser_logs(example)
      return unless example.metadata[:browser_logs]

      logs = example.metadata[:browser_logs]
      output.puts("  Browser logs:\n    #{logs.join("\n    ")}")
    end
  end
end

# Output browser logs after failed feature test
RSpec.configure do |config|
  config.after(type: :feature) do |example|
    Capybara::CaptureBrowserLogs.after_failed_example(example)
  end

  config.before(:suite) do
    Capybara::CaptureBrowserLogs.change_text_formatter_to_output_captured_browser_logs
  end
end
