# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'rack'
require 'erb'
require 'cgi'
require 'haml'
require 'fast_xs_extra'
require 'escape_utils'

module HamlBench
  extend Haml::Helpers
end

url = "https://en.wikipedia.org/wiki/Succession_to_the_British_throne"
html = `curl -s #{url}`
html = html.force_encoding('utf-8') if html.respond_to?(:force_encoding)
puts "Escaping #{html.bytesize} bytes of html from #{url}"

Benchmark.ips do |x|
  x.report "Rack::Utils.escape_html" do |times|
    times.times do
      Rack::Utils.escape_html(html)
    end
  end

  x.report "Haml::Helpers.html_escape" do |times|
    times.times do
      HamlBench.html_escape(html)
    end
  end

  x.report "ERB::Util.html_escape" do |times|
    times.times do
      ERB::Util.html_escape(html)
    end
  end

  x.report "CGI.escapeHTML" do |times|
    times.times do
      CGI.escapeHTML(html)
    end
  end

  x.report "String#gsub" do |times|
    html_escape = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;', "'" => '&#39;' }
    times.times do
      html.gsub(/[&"'><]/, html_escape)
    end
  end

  x.report "fast_xs_extra#fast_xs_html" do |times|
    times.times do
      html.fast_xs_html
    end
  end

  x.report "EscapeUtils.escape_html" do |times|
    times.times do
      EscapeUtils.escape_html(html)
    end
  end

  x.compare!
end
