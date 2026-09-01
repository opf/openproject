# frozen_string_literal: true

require "spec_helper"
require "support/browsers/browser_platform"

RSpec.describe BrowserPlatform do
  let(:app) { ->(_env) { [200, {}, []] } }

  # Real drivers, so `case` dispatches on the class; none of them starts a
  # browser until `browser` is called, which is the one method stubbed.
  def selenium_session(platform_name)
    capabilities = instance_double(Selenium::WebDriver::Remote::Capabilities, platform_name:)
    driver = Capybara::Selenium::Driver.new(app)
    allow(driver).to receive(:browser).and_return(instance_double(Selenium::WebDriver::Driver, capabilities:))
    instance_double(Capybara::Session, driver:)
  end

  def cuprite_session(user_agent)
    version = instance_double(Ferrum::Browser::VersionInfo, user_agent:)
    driver = Capybara::Cuprite::Driver.new(app)
    allow(driver).to receive(:browser).and_return(instance_double(Capybara::Cuprite::Browser, version:))
    instance_double(Capybara::Session, driver:)
  end

  def host_os(value)
    stub_const("RbConfig::CONFIG", RbConfig::CONFIG.merge("host_os" => value))
  end

  describe ".multi_select_modifier" do
    it "is Cmd when a Selenium browser runs on macOS, whatever the host" do
      host_os("linux-gnu")

      expect(described_class.multi_select_modifier(selenium_session("mac"))).to eq(:meta)
    end

    it "is Ctrl when a Selenium browser runs elsewhere, whatever the host" do
      host_os("darwin24")

      expect(described_class.multi_select_modifier(selenium_session("linux"))).to eq(:control)
    end

    it "reads the platform from a Cuprite browser's user agent" do
      host_os("darwin24")
      linux_ua = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36"

      expect(described_class.multi_select_modifier(cuprite_session(linux_ua))).to eq(:control)
    end

    it "falls back to the host when the browser reports no platform" do
      host_os("darwin24")

      expect(described_class.multi_select_modifier(selenium_session(nil))).to eq(:meta)
    end

    it "falls back to the host for a RackTest driver" do
      host_os("linux-gnu")
      session = instance_double(Capybara::Session, driver: Capybara::RackTest::Driver.new(app))

      expect(described_class.multi_select_modifier(session)).to eq(:control)
    end
  end
end
