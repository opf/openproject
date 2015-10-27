Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'

  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
    Selenium::WebDriver::Firefox::Binary.path

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['intl.accept_languages'] = 'en'

  # Turn off the super annoying popup!
  # see http://docs.travis-ci.com/user/gui-and-headless-browsers/#Selenium-and-Firefox-popups
  profile["network.http.prompt-temp-redirect"] = false

  Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
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
