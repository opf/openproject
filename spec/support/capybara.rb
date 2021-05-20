require 'socket'
require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'
require 'action_dispatch'

RSpec.configure do |_config|
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
    Capybara.server_host = ENV.fetch('CAPYBARA_APP_HOSTNAME', '0.0.0.0')
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
