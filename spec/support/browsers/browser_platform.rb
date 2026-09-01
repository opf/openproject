# frozen_string_literal: true

# The modifier a page under test honours for multi-select: Cmd on an Apple
# platform, Ctrl elsewhere. The browser under test decides, since a grid can
# run it on another OS than this host.
module BrowserPlatform
  module_function

  def multi_select_modifier(session = Capybara.current_session)
    apple?(session) ? :meta : :control
  end

  def apple?(session = Capybara.current_session)
    platform_name(session).match?(/mac|darwin|ios/i)
  end

  # Selenium and Cuprite can both drive a browser on another machine; only
  # the latter has no platform capability, but its user agent names the OS.
  def platform_name(session)
    driver = session.driver
    reported =
      case driver
      when Capybara::Selenium::Driver then driver.browser.capabilities.platform_name
      when Capybara::Cuprite::Driver then driver.browser.version.user_agent
      end

    reported.presence || RbConfig::CONFIG["host_os"]
  end
end
