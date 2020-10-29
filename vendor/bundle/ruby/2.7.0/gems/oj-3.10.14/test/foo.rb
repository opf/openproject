#!/usr/bin/env ruby

$: << File.dirname(__FILE__)
$oj_dir = File.dirname(File.expand_path(File.dirname(__FILE__)))
%w(lib ext).each do |dir|
  $: << File.join($oj_dir, dir)
end

require 'json'

t = [Time.now.utc]

puts "t.to_json - #{t.to_json}"

puts "--- active support"

require 'active_support'
require "active_support/json"

ActiveSupport::JSON::Encoding.use_standard_json_time_format = false

puts "t.as_json - #{t.as_json}"
puts "t.to_json - #{t.to_json}"

require 'oj'

t = [Time.now.utc]

puts "-----------------------"

#puts "t.as_json - #{t.as_json}"
puts "t.to_json - #{t.to_json}"

#Oj.mimic_JSON

#puts "Oj - t.as_json - #{t.as_json}"

puts "--- active support"

require 'active_support'
require "active_support/json"

ActiveSupport::JSON::Encoding.use_standard_json_time_format = false

puts "t.as_json - #{t.as_json}"
puts "t.to_json - #{t.to_json}"

puts "--- optimize"
Oj.optimize_rails

puts "t.as_json - #{t.as_json}"
puts "t.to_json - #{t.to_json}"
