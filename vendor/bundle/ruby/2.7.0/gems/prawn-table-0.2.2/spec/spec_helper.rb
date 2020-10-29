# encoding: utf-8

puts "Prawn specs: Running on Ruby Version: #{RUBY_VERSION}"

require "bundler"
Bundler.setup

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require_relative "../lib/prawn/table"

Prawn.debug = true

require "rspec"
require "mocha/api"
require "pdf/reader"
require "pdf/inspector"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/extensions/ and its subdirectories.
Dir[File.dirname(__FILE__) + "/extensions/**/*.rb"].each {|f| require f }

RSpec.configure do |config|
  config.mock_framework = :mocha
  config.include EncodingHelpers
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

def create_pdf(klass=Prawn::Document)
  @pdf = klass.new(:margin => 0)
end

RSpec::Matchers.define :have_parseable_xobjects do
  match do |actual|
    expect { PDF::Inspector::XObject.analyze(actual.render) }.not_to raise_error
    true
  end
  failure_message_for_should do |actual|
    "expected that #{actual}'s XObjects could be successfully parsed"
  end
end

# Make some methods public to assist in testing
module Prawn::Graphics
  public :map_to_absolute
end

