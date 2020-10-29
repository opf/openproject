# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'cgi'
require 'haml'
require 'escape_utils'

module HamlBench
  extend Haml::Helpers
end

url = "https://en.wikipedia.org/wiki/Succession_to_the_British_throne"
html = `curl -s #{url}`
html = html.force_encoding('binary') if html.respond_to?(:force_encoding)
escaped_html = EscapeUtils.escape_html(html)
puts "Unescaping #{escaped_html.bytesize} bytes of escaped html, from #{url}"

Benchmark.ips do |x|
  x.report "CGI.unescapeHTML" do |times|
    times.times do
      CGI.unescapeHTML(escaped_html)
    end
  end

  x.report "EscapeUtils.unescape_html" do |times|
    times.times do
      EscapeUtils.unescape_html(escaped_html)
    end
  end

  x.compare!
end
