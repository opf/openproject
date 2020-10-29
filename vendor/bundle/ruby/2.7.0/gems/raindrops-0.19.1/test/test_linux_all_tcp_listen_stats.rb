# -*- encoding: binary -*-
require 'test/unit'
require 'socket'
require 'raindrops'
require 'pp'
$stderr.sync = $stdout.sync = true

class TestLinuxAllTcpListenStats < Test::Unit::TestCase
  include Raindrops::Linux
  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'

  def test_print_all
    puts "EVERYTHING"
    pp Raindrops::Linux.tcp_listener_stats
    puts("-" * 72)
  end if $stdout.tty?

  def setup
    @socks = []
  end

  def teardown
    @socks.each { |io| io.closed? or io.close }
  end

  def new_server
    s = TCPServer.new TEST_ADDR, 0
    @socks << s
    [ s, s.addr[1] ]
  end

  def new_client(port)
    s = TCPSocket.new("127.0.0.1", port)
    @socks << s
    s
  end

  def new_accept(srv)
    c = srv.accept
    @socks << c
    c
  end

  def test_all_ports
    srv, port = new_server
    addr = "#{TEST_ADDR}:#{port}"
    all = Raindrops::Linux.tcp_listener_stats
    assert_equal [0,0], all[addr].to_a

    new_client(port)
    all = Raindrops::Linux.tcp_listener_stats
    assert_equal [0,1], all[addr].to_a

    new_client(port)
    all = Raindrops::Linux.tcp_listener_stats
    assert_equal [0,2], all[addr].to_a

    new_accept(srv)
    all = Raindrops::Linux.tcp_listener_stats
    assert_equal [1,1], all[addr].to_a

    new_accept(srv)
    all = Raindrops::Linux.tcp_listener_stats
    assert_equal [2,0], all[addr].to_a
  end
end if RUBY_PLATFORM =~ /linux/
