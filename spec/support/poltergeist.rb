require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,     phantomjs_logger: StringIO.new,
                                             timeout: 100,
                                             phantomjs_options: ['--load-images=no'])
end



# We make Poltergeist our default driver. We could have it set as a javascript
# driver only, but that would make us use two drivers (Poltergeist and rack),
# needlessly. Furthermore it would add the hassle of tagging js tests as so,
# and it should not matter if a test is using JS or not.
# Capybara.default_driver = :poltergeist
# Capybara.javascript_driver = :poltergeist
