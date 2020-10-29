# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.require :default, :test

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

eager_load!

# The default value for this setting is true in a standard Rails app,
# so it should be set to true here as well to reflect that.
I18n.enforce_available_locales = true

module Chunks
  def read_chunks(body)
    buffer = []
    body.each { |chunk| buffer << chunk }

    buffer
  end
end

RSpec.configure do |config|
  config.include Chunks
  config.include Rack::Test::Methods
  config.include Spec::Support::Helpers
  config.raise_errors_for_deprecations!
  config.filter_run_when_matching :focus
  config.warnings = true

  config.before(:each) { Grape::Util::InheritableSetting.reset_global! }

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end

require 'coveralls'
Coveralls.wear!
