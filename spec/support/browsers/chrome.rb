# rubocop:disable Metrics/PerceivedComplexity
def register_chrome(language, name: :"chrome_#{language}", headless: "old", override_time_zone: nil)
  Capybara.register_driver name do |app|
    options = Selenium::WebDriver::Chrome::Options.new

    if ActiveRecord::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_TESTING_NO_HEADLESS", nil))
      # Maximize the window however large the available space is
      options.add_argument("--start-maximized")
      # Open dev tools for quick access
      if ActiveRecord::Type::Boolean.new.cast(ENV.fetch("OPENPROJECT_TESTING_AUTO_DEVTOOLS", nil))
        options.add_argument("--auto-open-devtools-for-tabs")
      end
    else
      options.add_argument("--window-size=1920,1080")
      options.add_argument("--headless=#{headless}")
    end

    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-popup-blocking")
    options.add_argument("--lang=#{language}")
    options.add_preference("intl.accept_languages", language)
    # This is REQUIRED for running in a docker container
    # https://github.com/grosser/parallel_tests/issues/658
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-smooth-scrolling")
    # Disable "Select your search engine screen"
    options.add_argument("--disable-search-engine-choice-screen")

    options.add_preference(:download,
                           directory_upgrade: true,
                           prompt_for_download: false,
                           default_directory: DownloadList::SHARED_PATH.to_s)

    options.add_preference(:browser, set_download_behavior: { behavior: "allow" })

    options.logging_prefs = { browser: "ALL" }

    yield(options) if block_given?

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 180
    client.open_timeout = 180

    is_grid = ENV["SELENIUM_GRID_URL"].present?

    driver_opts = {
      browser: is_grid ? :remote : :chrome,
      options:,
      http_client: client
    }

    if is_grid
      driver_opts[:url] = ENV.fetch("SELENIUM_GRID_URL", nil)
    else
      driver_opts[:service] = Selenium::WebDriver::Service.chrome(
        args: ["--verbose", "--log-path=/tmp/chromedriver.log"]
      )
    end

    driver = Capybara::Selenium::Driver.new app, **driver_opts

    if !is_grid
      # Enable file downloads in headless mode
      # https://bugs.chromium.org/p/chromium/issues/detail?id=696481
      bridge = driver.browser.send :bridge

      bridge.http.call :post,
                       "/session/#{bridge.session_id}/chromium/send_command",
                       cmd: "Page.setDownloadBehavior",
                       params: { behavior: "allow", downloadPath: DownloadList::SHARED_PATH.to_s }

      if override_time_zone
        bridge.http.call :post,
                         "/session/#{bridge.session_id}/chromium/send_command",
                         cmd: "Emulation.setTimezoneOverride",
                         params: { timezoneId: override_time_zone }
      end
    end

    driver
  end

  Capybara::Screenshot.register_driver(name) do |driver, path|
    driver.browser.save_screenshot(path)
  end
end
# rubocop:enable Metrics/PerceivedComplexity

register_chrome "en"
# Register german locale for custom field decimal test
register_chrome "de"

Billy.configure do |c|
  c.proxy_host = Capybara.server_host
  if Capybara.server_port
    c.proxy_port = Capybara.server_port + 1000
  end
end

# Register mocking proxy driver
register_chrome "en", name: :chrome_billy do |options|
  options.add_argument("proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
  options.add_argument("proxy-bypass-list=127.0.0.1;localhost;#{Capybara.server_host}")

  options.accept_insecure_certs = true
end

# Register Revit add in
register_chrome "en", name: :chrome_revit_add_in do |options|
  options.add_argument("user-agent='foo bar Revit'")
end

register_chrome "en", name: :chrome_new_york_time_zone, override_time_zone: "America/New_York"
