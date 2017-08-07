require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'

RSpec.configure do
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :selenium
end

##
# Configure capybara-screenshot

# Remove old images automatically
Capybara::Screenshot.prune_strategy = :keep_last_run

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

  # use native instead of synthetic events
  # https://github.com/SeleniumHQ/selenium/wiki/DesiredCapabilities
  profile.native_events = true

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    profile: profile,
    http_client: client,
    desired_capabilities: capabilities
  )
end
