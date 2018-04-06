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
