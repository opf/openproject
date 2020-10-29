begin
  require 'simplecov'
  SimpleCov.start
  SimpleCov.command_name 'Shindo'
rescue LoadError => e
  $stderr.puts "not recording test coverage: #{e.inspect}"
end

require File.expand_path('../../lib/fog/aws', __FILE__)

Bundler.require(:test)

Excon.defaults.merge!(debug_request: true, debug_response: true)

require File.expand_path(File.join(File.dirname(__FILE__), 'helpers', 'mock_helper'))

# This overrides the default 600 seconds timeout during live test runs
unless Fog.mocking?
  Fog.timeout = ENV['FOG_TEST_TIMEOUT'] || 2_000
  Fog::Logger.warning "Setting default fog timeout to #{Fog.timeout} seconds"
end

def lorem_file
  File.open(File.dirname(__FILE__) + '/lorem.txt', 'r')
end

def array_differences(array_a, array_b)
  (array_a - array_b) | (array_b - array_a)
end
