if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'dry-equalizer'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!

  config.disable_monkey_patching!

  config.expect_with :rspec do |expect_with|
    expect_with.syntax = :expect
  end

  config.warnings = true
end
