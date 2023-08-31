module SeleniumHubWaiter
  module_function

  # frontend not fast enough to bind click handlers on buttons?
  # only happens when using the Selenium Hub
  def wait
    sleep 1 unless ENV.fetch("SELENIUM_GRID_URL", "").blank? && using_cuprite?
  end
end
