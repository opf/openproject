Capybara.register_driver :selenium do |app|
  require 'selenium/webdriver'

  Selenium::WebDriver::Firefox::Binary.path = ENV['FIREFOX_BINARY_PATH'] ||
    Selenium::WebDriver::Firefox::Binary.path

  Capybara::Selenium::Driver.new(app, browser: :firefox)
end

RSpec.configure do |config|
  config.around(:each, selenium: true) do |example|
    Capybara.javascript_driver = :selenium
    Capybara.default_wait_time = 5

    example.run

    Capybara.javascript_driver = :poltergeist
    Capybara.default_wait_time = 2
  end
end
