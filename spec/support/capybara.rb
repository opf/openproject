require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'rack_session_access/capybara'
require 'action_dispatch'

RSpec.configure do |config|
  Capybara.default_max_wait_time = 4
  Capybara.javascript_driver = :chrome_headless

  resized = false
  config.before(:each, js: true) do
    next if resized
    begin
      window = Capybara.current_session.current_window
      unless window.size == [1920, 1080]
        warn "Resizing Capybara current window to 1920x1080 (Size was #{window.size.inspect})"
        window.resize_to(1920, 1080)
      end

      resized = true
    rescue => e
      warn "Failed to update page width: #{e}"
      warn e.backtrace
    end
  end
end

##
# Configure capybara-screenshot

# Remove old images automatically
Capybara::Screenshot.prune_strategy = :keep_last_run

# Don't silence puma if we're using it
Capybara.register_server :thin do |app, port, host|
  require 'rack/handler/thin'
  Rack::Handler::Thin.run(app, Port: port, Host: host)
end
Capybara.server = :thin

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

Capybara.register_driver :firefox_headless do |app|
  require 'selenium/webdriver'

  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
                                              Selenium::WebDriver::Firefox::Binary.path

  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(marionette: true)
  capabilities["elementScrollBehavior"] = 1

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 180

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'
  profile['browser.download.dir'] = DownloadedFile::PATH.to_s
  profile['browser.download.folderList'] = 2
  profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv'

  # prevent stale firefoxCP processes
  profile['browser.tabs.remote.autostart'] = false
  profile['browser.tabs.remote.autostart.2'] = false

  # only one FF process
  profile['dom.ipc.processCount'] = 1

  # use native instead of synthetic events
  # https://github.com/SeleniumHQ/selenium/wiki/DesiredCapabilities
  profile.native_events = true

  options = Selenium::WebDriver::Firefox::Options.new
  options.profile = profile

  unless ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_NO_HEADLESS'])
    options.args << "--headless"
  end

  # If you need to trace the webdriver commands, un-comment this line
  # Selenium::WebDriver.logger.level = :info

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    options: options,
    http_client: client,
    desired_capabilities: capabilities
  )
end


Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-popup-blocking')
  options.add_argument('--window-size=1920,1080')

  options.add_preference(:download,
                         directory_upgrade: true,
                         prompt_for_download: false,
                         default_directory: DownloadedFile::PATH.to_s)

  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)

  bridge = driver.browser.send(:bridge)

  path = '/session/:session_id/chromium/send_command'
  path[':session_id'] = bridge.session_id

  bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
                   params: {
                     behavior: 'allow',
                     downloadPath: DownloadedFile::PATH.to_s
                   })

  driver
end
