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

# silence puma if we're using it
Capybara.server = :puma, { Silent: true }

Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end
