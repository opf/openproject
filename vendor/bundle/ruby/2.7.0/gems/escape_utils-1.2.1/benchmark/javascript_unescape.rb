# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'escape_utils'

url = "http://ajax.googleapis.com/ajax/libs/dojo/1.4.3/dojo/dojo.xd.js.uncompressed.js"
javascript = `curl -s #{url}`
javascript = javascript.force_encoding('utf-8') if javascript.respond_to?(:force_encoding)
escaped_javascript = EscapeUtils.escape_javascript(javascript)
puts "Escaping #{escaped_javascript.bytesize} bytes of javascript, from #{url}"

Benchmark.ips do |x|
  x.report "EscapeUtils.escape_javascript" do |times|
    times.times do
      EscapeUtils.unescape_javascript(escaped_javascript)
    end
  end
end
