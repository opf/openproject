require 'socket'
require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'
require 'action_dispatch'

RSpec.configure do |config|
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :chrome_en

  port = ENV.fetch('CAPYBARA_SERVER_PORT', ENV.fetch('TEST_ENV_NUMBER', '1').to_i + 3000).to_i
  if port > 0
    Capybara.server_port = port
  end
  Capybara.always_include_port = true

  ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
  hostname = ENV['CAPYBARA_DYNAMIC_HOSTNAME'].present? ? ip_address : ENV.fetch('CAPYBARA_APP_HOSTNAME', 'localhost')
  Capybara.server_host = ip_address
  Capybara.app_host = "http://#{hostname}"
end

##
# Configure capybara-screenshot

# Remove old images automatically
Capybara::Screenshot.prune_strategy = :keep_last_run

# silence puma if we're using it
Capybara.server = :puma, { Silent: true }

# Set up S3 uploads if desired
if ENV['OPENPROJECT_ENABLE_CAPYBARA_SCREENSHOT_S3_UPLOADS'] && ENV['AWS_ACCESS_KEY_ID']
  Capybara::Screenshot.s3_configuration = {
    s3_client_credentials: {
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('AWS_ACCESS_KEY_SECRET'),
      region: ENV.fetch('AWS_REGION', 'eu-west-1')
    },
    bucket_name: ENV.fetch('S3_BUCKET_NAME', 'openproject-travis-logs')
  }
end

Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end
