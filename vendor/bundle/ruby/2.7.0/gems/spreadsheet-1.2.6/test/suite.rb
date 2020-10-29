#!/usr/bin/env ruby
# suite.rb -- spreadsheet -- 22.12.2011 -- jsaak@napalm.hu
require 'rubygems'
require 'bundler'
require 'find'

$VERBOSE = true

here = File.dirname(__FILE__)

$: << here

Find.find(here) do |file|
  next if File.basename(file) == 'suite.rb'
  if file =~ /\.rb$/o
    require file[here.size+1..-1]
  end
end
