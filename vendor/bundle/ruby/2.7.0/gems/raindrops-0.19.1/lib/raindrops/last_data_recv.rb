# -*- encoding: binary -*-
require "raindrops"

# This is highly experimental!
#
# A self-contained Rack application for aggregating in the
# +tcpi_last_data_recv+ field in +struct+ +tcp_info+ defined in
# +/usr/include/linux/tcp.h+.  This is only useful for \Linux 2.6 and later.
# This primarily supports Unicorn and derived servers, but may also be
# used with any Ruby web server using the core TCPServer class in Ruby.
#
# Hitting the Rack endpoint configured for this application will return
# a an ASCII histogram response body with the following headers:
#
# - X-Count   - number of requests received
#
# The following headers are only present if X-Count is greater than one.
#
# - X-Min     - lowest last_data_recv time recorded (in milliseconds)
# - X-Max     - highest last_data_recv time recorded (in milliseconds)
# - X-Mean    - mean last_data_recv time recorded (rounded, in milliseconds)
# - X-Std-Dev - standard deviation of last_data_recv times
# - X-Outliers-Low - number of low outliers (hopefully many!)
# - X-Outliers-High - number of high outliers (hopefully zero!)
#
# == To use with Unicorn and derived servers (preload_app=false):
#
# Put the following in our Unicorn config file (not config.ru):
#
#   require "raindrops/last_data_recv"
#
# Then follow the instructions below for config.ru:
#
# == To use with any Rack server using TCPServer
#
# Setup a route for Raindrops::LastDataRecv in your Rackup config file
# (typically config.ru):
#
#   require "raindrops"
#   map "/raindrops/last_data_recv" do
#     run Raindrops::LastDataRecv.new
#   end
#   map "/" do
#     use SomeMiddleware
#     use MoreMiddleware
#     # ...
#     run YourAppHere.new
#   end
#
# == To use with any other Ruby web server that uses TCPServer
#
# Put the following in any piece of Ruby code loaded after the server has
# bound its TCP listeners:
#
#   ObjectSpace.each_object(TCPServer) do |s|
#     s.extend Raindrops::Aggregate::LastDataRecv
#   end
#
#   Thread.new do
#     Raindrops::Aggregate::LastDataRecv.default_aggregate.master_loop
#   end
#
# Then follow the above instructions for config.ru
#
class Raindrops::LastDataRecv
  # :stopdoc:

  # trigger autoloads
  if defined?(Unicorn)
    agg = Raindrops::Aggregate::LastDataRecv.default_aggregate
    AGGREGATE_THREAD = Thread.new { agg.master_loop }
  end
  # :startdoc

  def initialize(opts = {})
    if defined?(Unicorn::HttpServer::LISTENERS)
      Raindrops::Aggregate::LastDataRecv.cornify!
    end
    @aggregate =
      opts[:aggregate] || Raindrops::Aggregate::LastDataRecv.default_aggregate
  end

  def call(_)
    a = @aggregate
    count = a.count
    headers = {
      "Content-Type" => "text/plain",
      "X-Count" => count.to_s,
    }
    if count > 1
      headers["X-Min"] = a.min.to_s
      headers["X-Max"] = a.max.to_s
      headers["X-Mean"] = a.mean.round.to_s
      headers["X-Std-Dev"] = a.std_dev.round.to_s
      headers["X-Outliers-Low"] = a.outliers_low.to_s
      headers["X-Outliers-High"] = a.outliers_high.to_s
    end
    body = a.to_s
    headers["Content-Length"] = body.size.to_s
    [ 200, headers, [ body ] ]
  end
end
