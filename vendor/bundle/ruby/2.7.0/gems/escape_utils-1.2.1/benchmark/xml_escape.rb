# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'fast_xs'
require 'escape_utils'

url = "http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml"
xml = `curl -s #{url}`
xml = xml.force_encoding('binary') if xml.respond_to?(:force_encoding)
puts "Escaping #{xml.bytesize} bytes of xml, from #{url}"

Benchmark.ips do |x|
  x.report "fast_xs" do |times|
    times.times do
      xml.fast_xs
    end
  end

  x.report "EscapeUtils.escape_xml" do |times|
    times.times do
      EscapeUtils.escape_xml(xml)
    end
  end

  x.compare!
end
