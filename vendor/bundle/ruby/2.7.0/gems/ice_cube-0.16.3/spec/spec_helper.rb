require "bundler/setup"
require 'ice_cube'
require 'timeout'

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  # okay
end

IceCube.compatibility = 12

DAY = Time.utc(2010, 3, 1)
WEDNESDAY = Time.utc(2010, 6, 23, 5, 0, 0)

WORLD_TIME_ZONES = [
  'America/Anchorage',  # -1000 / -0900
  'Europe/London',      # +0000 / +0100
  'Pacific/Auckland',   # +1200 / +1300
]

# TODO: enable warnings here and update specs to call IceCube objects correctly
def Object.const_missing(sym)
  case sym
  when :Schedule, :Rule, :Occurrence, :TimeUtil, :ONE_DAY, :ONE_HOUR, :ONE_MINUTE
    # warn "Use IceCube::#{sym}", caller[0]
    IceCube.const_get(sym)
  else
    super
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Dir[File.dirname(__FILE__) + '/support/**/*'].each { |f| require f }

  config.warnings = true

  config.include WarningHelpers

  config.before :each do |example|
    if example.metadata[:requires_active_support]
      raise 'ActiveSupport required but not present' unless defined?(ActiveSupport)
    end
  end

  config.around :each, system_time_zone: true do |example|
    orig_zone = ENV['TZ']
    ENV['TZ'] = example.metadata[:system_time_zone]
    example.run
    ENV['TZ'] = orig_zone
  end

  config.around :each, locale: true do |example|
    orig_locale = I18n.locale
    I18n.locale = example.metadata[:locale]
    example.run
    I18n.locale = orig_locale
  end

  config.around :each, expect_warnings: true do |example|
    capture_warnings do
      example.run
    end
  end

  config.around :each do |example|
    Timeout.timeout(example.metadata.fetch(:timeout, 1)) do
      example.run
    end
  end
end
