class SeleniumHubWaiter
  # frontend not fast enough to bind click handlers on buttons?
  # only happens when using the Selenium Hub
  def self.wait
    sleep 1 if ENV.fetch("SELENIUM_GRID_URL", "").present?
  end
end
