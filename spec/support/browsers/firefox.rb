# Force the latest version of geckodriver using the webdriver gem
require 'webdrivers/geckodriver'

if ENV['CI']
  ::Webdrivers.logger.level = :DEBUG
  ::Webdrivers::Geckodriver.update
end


def register_firefox_headless(language, name: :"firefox_headless_#{language}")
  require 'selenium/webdriver'

  Capybara.register_driver name do |app|
    Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
      Selenium::WebDriver::Firefox::Binary.path

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.timeout = 180

    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['intl.accept_languages'] = language
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

    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)

    capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(
      loggingPrefs: { browser: 'ALL' }
    )

    yield(profile, options, capabilities) if block_given?

    unless ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_NO_HEADLESS'])
      options.args << "--headless"
    end

    # If you need to trace the webdriver commands, un-comment this line
    # Selenium::WebDriver.logger.level = :info

    driver = Capybara::Selenium::Driver.new(
      app,
      browser: :firefox,
      options: options,
      desired_capabilities: capabilities,

      http_client: client,
    )

    Capybara::Screenshot.register_driver(name) do |driver, path|
      driver.browser.save_screenshot(path)
    end

    driver
  end
end

register_firefox_headless 'en'
# Register german locale for custom field decimal test
register_firefox_headless 'de'

# Register mocking proxy driver
register_firefox_headless 'en', name: :headless_firefox_billy do |profile, options, capabilities|
  profile.assume_untrusted_certificate_issuer = false
  profile.proxy = Selenium::WebDriver::Proxy.new(
    http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
    ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")


  capabilities[:accept_insecure_certs] = true
end

# Resize window if firefox
RSpec.configure do |config|
  config.before(:each, driver: Proc.new { |val| val.to_s.start_with? 'firefox_headless_' }) do
    Capybara.page.driver.browser.manage.window.maximize
  end
end