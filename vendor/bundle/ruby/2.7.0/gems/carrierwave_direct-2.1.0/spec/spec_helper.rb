# encoding: utf-8

require 'carrierwave_direct'
require 'json'
require 'timecop'
begin
  require 'byebug'
rescue LoadError
  puts "Byebug not installed"
end

require File.dirname(__FILE__) << '/support/view_helpers' # Catch dependency order

Dir[ File.dirname(__FILE__) << "/support/**/*.rb"].each {|file| require file }

module Rails
  def self.env
    ActiveSupport::StringInquirer.new("test")
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:expect, :should]
  end
end
