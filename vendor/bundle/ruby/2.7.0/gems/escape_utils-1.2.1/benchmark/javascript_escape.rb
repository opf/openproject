# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'action_view'
require 'escape_utils'

class ActionPackBench
  extend ActionView::Helpers::JavaScriptHelper
end

url = "http://ajax.googleapis.com/ajax/libs/dojo/1.4.3/dojo/dojo.xd.js.uncompressed.js"
javascript = `curl -s #{url}`
javascript = javascript.force_encoding('utf-8') if javascript.respond_to?(:force_encoding)
puts "Escaping #{javascript.bytesize} bytes of javascript, from #{url}"

Benchmark.ips do |x|
  x.report "ActionView::Helpers::JavaScriptHelper#escape_javascript" do |times|
    times.times do
      ActionPackBench.escape_javascript(javascript)
    end
  end

  x.report "EscapeUtils.escape_javascript" do |times|
    times.times do
      EscapeUtils.escape_javascript(javascript)
    end
  end

  x.compare!
end
