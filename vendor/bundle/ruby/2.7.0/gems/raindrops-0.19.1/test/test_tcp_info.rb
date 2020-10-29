# -*- encoding: binary -*-
require 'test/unit'
require 'tempfile'
require 'raindrops'
require 'socket'
require 'pp'
$stderr.sync = $stdout.sync = true
class TestTCP_Info < Test::Unit::TestCase

  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'

  # Linux kernel commit 5ee3afba88f5a79d0bff07ddd87af45919259f91
  TCP_INFO_useful_listenq = `uname -r`.strip >= '2.6.24'

  def test_tcp_server_unacked
    return if RUBY_PLATFORM !~ /linux/ # unacked not implemented on others...
    s = TCPServer.new(TEST_ADDR, 0)
    rv = Raindrops::TCP_Info.new s
    c = TCPSocket.new TEST_ADDR, s.addr[1]
    tmp = Raindrops::TCP_Info.new s
    TCP_INFO_useful_listenq and assert_equal 1, tmp.unacked

    assert_equal 0, rv.unacked
    a = s.accept
    tmp = Raindrops::TCP_Info.new s
    assert_equal 0, tmp.unacked
    before = tmp.object_id

    tmp.get!(s)
    assert_equal before, tmp.object_id

  ensure
    [ c, a, s ].compact.each(&:close)
  end

  def test_accessors
    s = TCPServer.new TEST_ADDR, 0
    tmp = Raindrops::TCP_Info.new s
    tcp_info_methods = tmp.methods - Object.new.methods
    assert tcp_info_methods.size >= 32
    tcp_info_methods.each do |m|
      next if m.to_sym == :get!
      next if ! tmp.respond_to?(m)
      val = tmp.__send__ m
      assert_kind_of Integer, val
      assert val >= 0
    end
    assert tmp.respond_to?(:state), 'every OS knows about TCP state, right?'
  ensure
    s.close
  end

  def test_tcp_server_delayed
    delay = 0.010
    delay_ms = (delay * 1000).to_i
    s = TCPServer.new(TEST_ADDR, 0)
    c = TCPSocket.new TEST_ADDR, s.addr[1]
    c.syswrite "."
    sleep(delay * 1.2)
    a = s.accept
    i = Raindrops::TCP_Info.new(a)
    assert i.last_data_recv >= delay_ms, "#{i.last_data_recv} < #{delay_ms}"
  ensure
    c.close if c
    a.close if a
    s.close
  end

  def test_tcp_server_state_closed
    s = TCPServer.new(TEST_ADDR, 0)
    c = TCPSocket.new(TEST_ADDR, s.addr[1])
    i = Raindrops::TCP_Info.allocate
    a = s.accept
    i.get!(a)
    state = i.state
    if Raindrops.const_defined?(:TCP)
      assert_equal state, Raindrops::TCP[:ESTABLISHED]
    end
    c = c.close
    sleep(0.01) # wait for kernel to update state
    i.get!(a)
    assert_not_equal state, i.state
  ensure
    s.close if s
    c.close if c
    a.close if a
  end
end if defined? Raindrops::TCP_Info
