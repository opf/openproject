Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'

  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
    Selenium::WebDriver::Firefox::Binary.path


  capabilities = Selenium::WebDriver::Remote::Capabilities.internet_explorer
  capabilities["elementScrollBehavior"] = 1

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    profile: profile,
    desired_capabilities: capabilities
  )
end

# RSpec.configure do |config|
#   config.around(:each, selenium: true) do |example|
#     Capybara.javascript_driver = :selenium
#     Capybara.default_wait_time = 5
#
#     example.run
#
#     Capybara.javascript_driver = :poltergeist
#     Capybara.default_wait_time = 2
#   end
# end

# Use selenium until we upgraded jenkins workers
Capybara.javascript_driver = :selenium
