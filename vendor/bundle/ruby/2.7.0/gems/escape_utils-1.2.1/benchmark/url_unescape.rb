# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'rack'
require 'cgi'
require 'url_escape'
require 'fast_xs_extra'
require 'escape_utils'

url = "https://www.yourmom.com/cgi-bin/session.cgi?sess_args=mYHcEA  dh435dqUs0moGHeeAJTSLLbdbcbd9ef----,574b95600e9ab7d27eb0bf524ac68c27----"
url = url.force_encoding('us-ascii') if url.respond_to?(:force_encoding)
escaped_url = EscapeUtils.escape_url(url)
puts "Escaping a #{url.bytesize} byte URL"

Benchmark.ips do |x|
  x.report "Rack::Utils.unescape" do |times|
    times.times do
      Rack::Utils.unescape(escaped_url)
    end
  end

  x.report "CGI.unescape" do |times|
    times.times do
      CGI.unescape(escaped_url)
    end
  end

  x.report "URLEscape#unescape" do |times|
    times.times do
      URLEscape.unescape(escaped_url)
    end
  end

  x.report "fast_xs_extra#fast_uxs_cgi" do |times|
    times.times do
      url.fast_uxs_cgi
    end
  end

  x.report "EscapeUtils.unescape_url" do |times|
    times.times do
      EscapeUtils.unescape_url(escaped_url)
    end
  end

  x.compare!
end
