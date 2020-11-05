# Force the latest version of geckodriver using the webdriver gem
require 'webdrivers/geckodriver'

::Webdrivers.logger.level = :DEBUG

if ENV['CI']
  ::Webdrivers::Geckodriver.update
end


def register_firefox(language, name: :"firefox_#{language}")
  require 'selenium/webdriver'

  Capybara.register_driver name do |app|
    if ENV['CI']
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 180
    end

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

    if ENV['CI']
      driver = Capybara::Selenium::Driver.new(
        app,
        browser: :firefox,
        desired_capabilities: capabilities,
        options: options,
        http_client: client
      )
    else
      driver = Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: ENV['SELENIUM_GRID_URL'],
        desired_capabilities: capabilities,
        options: options
      )
    end

    Capybara::Screenshot.register_driver(name) do |driver, path|
      driver.browser.save_screenshot(path)
    end

    driver
  end
end

register_firefox 'en'
# Register german locale for custom field decimal test
register_firefox 'de'

# Register mocking proxy driver
register_firefox 'en', name: :firefox_billy do |profile, options, capabilities|
  profile.assume_untrusted_certificate_issuer = false
  profile.proxy = Selenium::WebDriver::Proxy.new(
    http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
    ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")


  capabilities[:accept_insecure_certs] = true
end