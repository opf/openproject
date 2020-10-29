#!/usr/bin/env ruby

$: << File.dirname(__FILE__)
$oj_dir = File.dirname(File.expand_path(File.dirname(__FILE__)))
%w(lib ext).each do |dir|
  $: << File.join($oj_dir, dir)
end

require 'active_support'
require "active_support/json"

$s = "\u2014 & \n \u{1F618}"

=begin
def check(label)
  puts "\n--- #{label} --------------------"

  ActiveSupport::JSON::Encoding.use_standard_json_time_format = true
  puts "with standard_json == true: t.to_json - #{$t.to_json}"
  ActiveSupport::JSON::Encoding.use_standard_json_time_format = false
  puts "with standard_json == false: t.to_json - #{$t.to_json}"
end

check('Before Oj')
=end

require 'oj'

ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false
puts "ActiveSupport.encode(s) - #{ActiveSupport::JSON.encode($s)}"

Oj.optimize_rails
Oj.default_options = { mode: :rails }

puts "Oj.dump(s) - #{Oj.dump($s)}"
