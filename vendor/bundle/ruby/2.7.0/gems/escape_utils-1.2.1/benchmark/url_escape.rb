# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'benchmark/ips'

require 'rack'
require 'erb'
require 'cgi'
require 'url_escape'
require 'fast_xs_extra'
require 'escape_utils'

url = "https://www.yourmom.com/cgi-bin/session.cgi?sess_args=mYHcEA  dh435dqUs0moGHeeAJTSLLbdbcbd9ef----,574b95600e9ab7d27eb0bf524ac68c27----"
url = url.force_encoding('us-ascii') if url.respond_to?(:force_encoding)
puts "Escaping a #{url.bytesize} byte URL times"

Benchmark.ips do |x|
  x.report "ERB::Util.url_encode" do |times|
    times.times do
      ERB::Util.url_encode(url)
    end
  end

  x.report "Rack::Utils.escape" do |times|
    times.times do
      Rack::Utils.escape(url)
    end
  end

  x.report "CGI.escape" do |times|
    times.times do
      CGI.escape(url)
    end
  end

  x.report "URLEscape#escape" do |times|
    times.times do
      URLEscape.escape(url)
    end
  end

  x.report "fast_xs_extra#fast_xs_url" do |times|
    times.times do
      url.fast_xs_url
    end
  end

  x.report "EscapeUtils.escape_url" do |times|
    times.times do
      EscapeUtils.escape_url(url)
    end
  end

  x.compare!
end
