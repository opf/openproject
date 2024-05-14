module BrowserHelper
  ##
  # Browser specific classes for browser-specific fixes
  # or mobile detection
  def browser_specific_classes
    [].tap do |classes|
      classes << "-browser-chrome" if browser.chrome? || browser.chromium_based?
      classes << "-browser-firefox" if browser.firefox?
      classes << "-browser-safari" if browser.safari?
      classes << "-browser-edge" if browser.edge?

      classes << "-browser-mobile" if browser.device.mobile?
      classes << "-browser-windows" if browser.platform.windows?
    end
  end
end
