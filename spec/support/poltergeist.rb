require 'capybara/poltergeist'
# Disable using poltergeist until we upgraded jenkins workers
# Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = {
    js_errors: false,
    window_size: [1200, 1000],
    timeout: 60
  }
  Capybara::Poltergeist::Driver.new(app, options)
end
