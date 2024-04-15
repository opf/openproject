require "socket"

def register_firefox(language, name: :"firefox_#{language}")
  require "selenium/webdriver"

  Capybara.register_driver name do |app|
    client = if ENV["CI"]
               Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 180,
                                                              read_timeout: 180)
             end

    profile = Selenium::WebDriver::Firefox::Profile.new
    profile["intl.accept_languages"] = language
    profile["browser.download.dir"] = DownloadList::SHARED_PATH.to_s
    profile["browser.download.folderList"] = 2
    profile["browser.helperApps.neverAsk.saveToDisk"] = "text/csv"

    # prevent stale firefoxCP processes
    profile["browser.tabs.remote.autostart"] = false
    profile["browser.tabs.remote.autostart.2"] = false

    # only one FF process
    profile["dom.ipc.processCount"] = 1

    profile["general.smoothScroll"] = false

    options = Selenium::WebDriver::Firefox::Options.new(profile:)

    yield(profile, options) if block_given?

    unless ActiveRecord::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_TESTING_NO_HEADLESS", nil))
      options.args << "--headless"
    end

    if ActiveRecord::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_TESTING_AUTO_DEVTOOLS", nil))
      options.args << "--devtools"
    end

    is_grid = ENV["SELENIUM_GRID_URL"].present?

    driver_opts = {
      browser: is_grid ? :remote : :firefox,
      url: ENV.fetch("SELENIUM_GRID_URL", nil),
      http_client: client,
      options:
    }

    driver = Capybara::Selenium::Driver.new app, **driver_opts

    Capybara::Screenshot.register_driver(name) do |driver, path|
      driver.browser.save_screenshot(path)
    end

    driver
  end
end

register_firefox "en"
# Register german locale for custom field decimal test
register_firefox "de"
