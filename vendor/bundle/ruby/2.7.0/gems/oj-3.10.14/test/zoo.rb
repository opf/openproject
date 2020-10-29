#!/usr/bin/env ruby

#require 'json'

$: << File.dirname(__FILE__)
require 'helper'
require 'oj'

Oj.mimic_JSON
puts "\u3074"

puts JSON.dump(["\u3074"])
puts JSON.generate(["\u3074"])
