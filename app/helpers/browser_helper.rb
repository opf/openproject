module BrowserHelper
  ##
  # Instead of defining what makes up a modern user,
  # only define those where we want to show a warning.
  #
  # Uses the +browser+ gem.
  def unsupported_browser?
    RequestStore.fetch(:unsupported_browser) do
      # Any version of IE
      return true if browser.ie?

      version = browser.version.to_i

      # Older versions behind last ESR FF
      return true if browser.firefox? && version < 60

      # Chrome versions older than a year
      return true if browser.chrome? && version < 65

      # Older version of safari
      return true if browser.safari? && version < 12

      # Older version of EDGE
      return true if browser.edge? && version < 18

      false
    end
  end

  ##
  # Browser specific classes for browser-specific fixes
  # or mobile detection
  def browser_specific_classes
    [].tap do |classes|
      classes << '-browser-chrome' if browser.chrome?
      classes << '-browser-firefox' if browser.firefox?
      classes << '-browser-safari' if browser.safari?
      classes << '-browser-edge' if browser.edge?

      classes << '-browser-mobile' if browser.device.mobile?
      classes << '-browser-windows' if browser.platform.windows?
      classes << '-unsupported-browser' if unsupported_browser?
    end
  end
end
