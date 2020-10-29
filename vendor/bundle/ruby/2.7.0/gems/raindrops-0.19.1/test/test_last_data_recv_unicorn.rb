# -*- encoding: binary -*-
require "./test/rack_unicorn"
require "tempfile"
require "net/http"

$stderr.sync = $stdout.sync = true
pmq = begin
  Raindrops::Aggregate::PMQ
rescue LoadError => e
  warn "W: #{e} skipping #{__FILE__}"
  false
end
if RUBY_VERSION.to_f < 1.9
  pmq = false
  warn "W: skipping test=#{__FILE__}, only Ruby 1.9 supported for now"
end

class TestLastDataRecvUnicorn < Test::Unit::TestCase
  def setup
    @queue = "/test.#{rand}"
    @host = ENV["UNICORN_TEST_ADDR"] || "127.0.0.1"
    @sock = TCPServer.new @host, 0
    @port = @sock.addr[1]
    ENV["UNICORN_FD"] = @sock.fileno.to_s
    @host_with_port = "#@host:#@port"
    @cfg = Tempfile.new 'unicorn_config_file'
    @cfg.puts "require 'raindrops'"
    @cfg.puts "preload_app true"
      ENV['RAINDROPS_MQUEUE'] = @queue
    # @cfg.puts "worker_processes 4"
    @opts = { :listeners => [ @host_with_port ], :config_file => @cfg.path }
  end

  def test_auto_listener
    @srv = fork {
      Thread.abort_on_exception = true
      app = %q!Rack::Builder.new do
        map("/ldr") { run Raindrops::LastDataRecv.new }
        map("/") { run Rack::Lobster.new }
      end.to_app!
      def app.arity; 0; end
      def app.call; eval self; end
      Unicorn::HttpServer.new(app, @opts).start.join
    }
    400.times { assert_kind_of Net::HTTPSuccess, get("/") }
    resp = get("/ldr")
    # # p(resp.methods - Object.methods)
    # resp.each_header { |k,v| p [k, "=" , v] }
    assert resp.header["x-count"]
    assert resp.header["x-min"]
    assert resp.header["x-max"]
    assert resp.header["x-mean"]
    assert resp.header["x-std-dev"]
    assert resp.header["x-outliers-low"]
    assert resp.header["x-outliers-high"]
    assert resp.body.size > 0
  end

  def get(path)
    Net::HTTP.start(@host, @port) { |http| http.get path }
  end

  def teardown
    Process.kill :QUIT, @srv
    _, status = Process.waitpid2 @srv
    assert status.success?
    POSIX_MQ.unlink @queue
  end
end if defined?(Unicorn) && RUBY_PLATFORM =~ /linux/ && pmq
