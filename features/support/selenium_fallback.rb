Around('@selenium') do |scenario, block|
  Capybara.current_driver = :selenium
  Capybara.default_wait_time = 10

  block.call

  Capybara.use_default_driver
  Capybara.default_wait_time = 2
end
