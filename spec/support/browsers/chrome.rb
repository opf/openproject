# Force the latest version of chromedriver using the webdriver gem
require 'webdrivers/chromedriver'

def register_chrome(language, name: :"chrome_#{language}")
  Capybara.register_driver name do |app|
    options = Selenium::WebDriver::Chrome::Options.new

    if ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_NO_HEADLESS'])
      # Maximize the window however large the available space is
      options.add_argument('--start-maximized')
      # Open dev tools for quick access
      if ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_TESTING_AUTO_DEVTOOLS'])
        options.add_argument('--auto-open-devtools-for-tabs')
      end
    else
      options.add_argument('--window-size=1920,1080')
      options.add_argument('--headless')
    end

    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-popup-blocking')
    options.add_argument("--lang=#{language}")
    # This is REQUIRED for running in a docker container
    # https://github.com/grosser/parallel_tests/issues/658
    options.add_argument('--disable-dev-shm-usage')

    options.add_preference(:download,
                           directory_upgrade: true,
                           prompt_for_download: false,
                           default_directory: DownloadList::SHARED_PATH.to_s)

    options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      loggingPrefs: { browser: 'ALL' }
    )

    yield(options, capabilities) if block_given?

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 180
    client.open_timeout = 180

    is_grid = ENV['SELENIUM_GRID_URL'].present?

    driver_opts = {
      browser: is_grid ? :remote : :chrome,
      desired_capabilities: capabilities,
      http_client: client,
      options: options,
    }

    if is_grid
      driver_opts[:url] = ENV['SELENIUM_GRID_URL']
    else
      driver_opts[:service] = ::Selenium::WebDriver::Service.chrome(
        args: { verbose: true, log_path: '/tmp/chromedriver.log' }
      )
    end

    driver = Capybara::Selenium::Driver.new app, **driver_opts

    if !is_grid
      # Enable file downloads in headless mode
      # https://bugs.chromium.org/p/chromium/issues/detail?id=696481
      bridge = driver.browser.send :bridge

      bridge.http.call :post,
                       "/session/#{bridge.session_id}/chromium/send_command",
                       cmd: 'Page.setDownloadBehavior',
                       params: { behavior: 'allow', downloadPath: DownloadList::SHARED_PATH.to_s }
    end

    driver
  end

  Capybara::Screenshot.register_driver(name) do |driver, path|
    driver.browser.save_screenshot(path)
  end
end

register_chrome 'en'
# Register german locale for custom field decimal test
register_chrome 'de'

Billy.configure do |c|
  c.proxy_host = Capybara.server_host
  if Capybara.server_port
    c.proxy_port = Capybara.server_port + 1000
  end
end

# Register mocking proxy driver
register_chrome 'en', name: :chrome_billy do |options, capabilities|
  options.add_argument("proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
  options.add_argument("proxy-bypass-list=127.0.0.1;localhost;#{Capybara.server_host}")

  capabilities[:acceptInsecureCerts] = true
end

# Register Revit add in
register_chrome 'en', name: :chrome_revit_add_in do |options, _capabilities|
  options.add_argument("user-agent='foo bar Revit'")
end
