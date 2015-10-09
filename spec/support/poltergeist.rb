require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = { js_errors: false, window_size: [1200, 1000] }
  Capybara::Poltergeist::Driver.new(app, options)
end
