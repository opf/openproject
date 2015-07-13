require 'capybara/rails'

Capybara.javascript_driver = :webkit
Capybara.default_wait_time = 2


require 'capybara-screenshot/rspec'
Capybara::Screenshot.autosave_on_failure = false


