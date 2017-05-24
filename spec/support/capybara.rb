require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'

RSpec.configure do
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :selenium
end

Rails.application.config do
  config.middleware.use RackSessionAccess::Middleware
end

Capybara.register_server :thin do |app, port, host|
  require 'rack/handler/thin'
  Rack::Handler::Thin.run(app, Port: port, Host: host)
end
Capybara.server = :thin

Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'

  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
                                              Selenium::WebDriver::Firefox::Binary.path

  # need to disable marionette as noted
  # https://github.com/teamcapybara/capybara#capybara
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(marionette: false)
  capabilities["elementScrollBehavior"] = 1

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 180

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'

  profile['browser.download.dir'] = DownloadedFile::PATH.to_s
  profile['browser.download.folderList'] = 2

  profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv'

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    profile: profile,
    http_client: client,
    desired_capabilities: capabilities
  )
end
