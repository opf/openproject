# -*- encoding: binary -*-
require 'raindrops'

# Raindrops::Middleware is Rack middleware that allows snapshotting
# current activity from an HTTP request.  For all operating systems,
# it returns at least the following fields:
#
# * calling - the number of application dispatchers on your machine
# * writing - the number of clients being written to on your machine
#
# Additional fields are available for \Linux users.
#
# It should be loaded at the top of Rack middleware stack before other
# middlewares for maximum accuracy.
#
# === Usage (Rainbows!/Unicorn preload_app=false)
#
# If you're using preload_app=false (the default) in your Rainbows!/Unicorn
# config file, you'll need to create the global Stats object before
# forking.
#
#    require 'raindrops'
#    $stats ||= Raindrops::Middleware::Stats.new
#
# In your Rack config.ru:
#
#    use Raindrops::Middleware, :stats => $stats
#
# === Usage (Rainbows!/Unicorn preload_app=true)
#
# If you're using preload_app=true in your Rainbows!/Unicorn
# config file, just add the middleware to your stack:
#
# In your Rack config.ru:
#
#    use Raindrops::Middleware
#
# === Linux-only extras!
#
# To get bound listener statistics under \Linux, you need to specify the
# listener names for your server.  You can even include listen sockets for
# *other* servers on the same machine.  This can be handy for monitoring
# your nginx proxy as well.
#
# In your Rack config.ru, just pass the :listeners argument as an array of
# strings (along with any other arguments).  You can specify any
# combination of TCP or Unix domain socket names:
#
#    use Raindrops::Middleware, :listeners => %w(0.0.0.0:80 /tmp/.sock)
#
# If you're running Unicorn 0.98.0 or later, you don't have to pass in
# the :listeners array, Raindrops will automatically detect the listeners
# used by Unicorn master process.  This does not detect listeners in
# different processes, of course.
#
# The response body includes the following stats for each listener
# (see also Raindrops::ListenStats):
#
# * active - total number of active clients on that listener
# * queued - total number of queued (pre-accept()) clients on that listener
#
# = Demo Server
#
# There is a server running this middleware (and Watcher) at
#  https://yhbt.net/raindrops-demo/_raindrops
#
# Also check out the Watcher demo at https://yhbt.net/raindrops-demo/
#
# The demo server is only limited to 30 users, so be sure not to abuse it
# by using the /tail/ endpoint too much.
#
class Raindrops::Middleware
  attr_accessor :app, :stats, :path, :tcp, :unix # :nodoc:

  # A Raindrops::Struct used to count the number of :calling and :writing
  # clients.  This struct is intended to be shared across multiple processes
  # and both counters are updated atomically.
  #
  # This is supported on all operating systems supported by Raindrops
  Stats = Raindrops::Struct.new(:calling, :writing)

  # :stopdoc:
  require "raindrops/middleware/proxy"
  # :startdoc:

  # +app+ may be any Rack application, this middleware wraps it.
  # +opts+ is a hash that understands the following members:
  #
  # * :stats - Raindrops::Middleware::Stats struct (default: Stats.new)
  # * :path - HTTP endpoint used for reading the stats (default: "/_raindrops")
  # * :listeners - array of host:port or socket paths (default: from Unicorn)
  def initialize(app, opts = {})
    @app = app
    @stats = opts[:stats] || Stats.new
    @path = opts[:path] || "/_raindrops"
    tmp = opts[:listeners]
    if tmp.nil? && defined?(Unicorn) && Unicorn.respond_to?(:listener_names)
      tmp = Unicorn.listener_names
    end
    @tcp = @unix = nil

    if tmp
      @tcp = tmp.grep(/\A.+:\d+\z/)
      @unix = tmp.grep(%r{\A/})
      @tcp = nil if @tcp.empty?
      @unix = nil if @unix.empty?
    end
  end

  # standard Rack endpoint
  def call(env) # :nodoc:
    env['PATH_INFO'] == @path and return stats_response
    begin
      @stats.incr_calling

      status, headers, body = @app.call(env)
      rv = [ status, headers, Proxy.new(body, @stats) ]

      # the Rack server will start writing headers soon after this method
      @stats.incr_writing
      rv
    ensure
      @stats.decr_calling
    end
  end

  def stats_response  # :nodoc:
    body = "calling: #{@stats.calling}\n" \
           "writing: #{@stats.writing}\n"

    if defined?(Raindrops::Linux.tcp_listener_stats)
      Raindrops::Linux.tcp_listener_stats(@tcp).each do |addr,stats|
        body << "#{addr} active: #{stats.active}\n" \
                "#{addr} queued: #{stats.queued}\n"
      end if @tcp
      Raindrops::Linux.unix_listener_stats(@unix).each do |addr,stats|
        body << "#{addr} active: #{stats.active}\n" \
                "#{addr} queued: #{stats.queued}\n"
      end if @unix
    end

    headers = {
      "Content-Type" => "text/plain",
      "Content-Length" => body.size.to_s,
    }
    [ 200, headers, [ body ] ]
  end
end
