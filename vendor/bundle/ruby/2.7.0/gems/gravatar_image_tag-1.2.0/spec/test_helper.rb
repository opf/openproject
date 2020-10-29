require 'rubygems'
#require 'spec'
require 'active_support'
require 'action_view'
require 'digest/md5'
require 'uri'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
