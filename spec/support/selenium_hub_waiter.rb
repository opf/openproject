module SeleniumHubWaiter
  module_function

  # frontend not fast enough to bind click handlers on buttons?
  # only happens when using the Selenium Hub
  def wait
    sleep 1 if ENV.fetch("SELENIUM_GRID_URL", "").present?
  end
end
