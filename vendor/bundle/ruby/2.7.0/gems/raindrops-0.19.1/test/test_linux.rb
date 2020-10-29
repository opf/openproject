# -*- encoding: binary -*-
require 'test/unit'
require 'tempfile'
require 'raindrops'
require 'socket'
require 'pp'
$stderr.sync = $stdout.sync = true

class TestLinux < Test::Unit::TestCase
  include Raindrops::Linux

  TEST_ADDR = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'

  def setup
    @to_close = []
  end

  def teardown
    @to_close.each { |io| io.close unless io.closed? }
  end

  def test_unix
    tmp = Tempfile.new("\xde\xad\xbe\xef") # valid path, really :)
    File.unlink(tmp.path)
    us = UNIXServer.new(tmp.path)
    stats = unix_listener_stats([tmp.path])
    assert_equal 1, stats.size
    assert_equal 0, stats[tmp.path].active
    assert_equal 0, stats[tmp.path].queued

    @to_close << UNIXSocket.new(tmp.path)
    stats = unix_listener_stats([tmp.path])
    assert_equal 1, stats.size
    assert_equal 0, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued

    @to_close << UNIXSocket.new(tmp.path)
    stats = unix_listener_stats([tmp.path])
    assert_equal 1, stats.size
    assert_equal 0, stats[tmp.path].active
    assert_equal 2, stats[tmp.path].queued

    @to_close << us.accept
    stats = unix_listener_stats([tmp.path])
    assert_equal 1, stats.size
    assert_equal 1, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued
  end

  def test_unix_all
    tmp = Tempfile.new("\xde\xad\xbe\xef") # valid path, really :)
    File.unlink(tmp.path)
    us = UNIXServer.new(tmp.path)
    @to_close << UNIXSocket.new(tmp.path)
    stats = unix_listener_stats
    assert_equal 0, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued

    @to_close << UNIXSocket.new(tmp.path)
    stats = unix_listener_stats
    assert_equal 0, stats[tmp.path].active
    assert_equal 2, stats[tmp.path].queued

    @to_close << us.accept
    stats = unix_listener_stats
    assert_equal 1, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued
  end

  def test_unix_all_unused
    tmp = Tempfile.new("\xde\xad\xbe\xef") # valid path, really :)
    File.unlink(tmp.path)
    us = UNIXServer.new(tmp.path)
    stats = unix_listener_stats
    assert stats.keys.include?(tmp.path), stats.inspect

    assert_equal 0, stats[tmp.path].active
    assert_equal 0, stats[tmp.path].queued
    us.close
  end

  def test_unix_resolves_symlinks
    tmp = Tempfile.new("\xde\xad\xbe\xef") # valid path, really :)
    File.unlink(tmp.path)
    us = UNIXServer.new(tmp.path)

    # Create a symlink
    link = Tempfile.new("somethingelse")
    File.unlink(link.path) # We need an available name, not an actual file
    File.symlink(tmp.path, link.path)

    @to_close << UNIXSocket.new(tmp.path)
    stats = unix_listener_stats
    assert_equal 0, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued

    @to_close << UNIXSocket.new(link.path)
    stats = unix_listener_stats([link.path])
    assert_equal 0, stats[link.path].active
    assert_equal 2, stats[link.path].queued

    assert_equal stats[link.path].object_id, stats[tmp.path].object_id

    @to_close << us.accept
    stats = unix_listener_stats
    assert_equal 1, stats[tmp.path].active
    assert_equal 1, stats[tmp.path].queued
  end

  def test_tcp
    s = TCPServer.new(TEST_ADDR, 0)
    port = s.addr[1]
    addr = "#{TEST_ADDR}:#{port}"
    addrs = [ addr ]
    stats = tcp_listener_stats(addrs)
    assert_equal 1, stats.size
    assert_equal 0, stats[addr].queued
    assert_equal 0, stats[addr].active

    @to_close << TCPSocket.new(TEST_ADDR, port)
    stats = tcp_listener_stats(addrs)
    assert_equal 1, stats.size
    assert_equal 1, stats[addr].queued
    assert_equal 0, stats[addr].active

    @to_close << s.accept
    stats = tcp_listener_stats(addrs)
    assert_equal 1, stats.size
    assert_equal 0, stats[addr].queued
    assert_equal 1, stats[addr].active
  end

  def test_tcp_reuse_sock
    nlsock = Raindrops::InetDiagSocket.new
    s = TCPServer.new(TEST_ADDR, 0)
    port = s.addr[1]
    addr = "#{TEST_ADDR}:#{port}"
    addrs = [ addr ]
    stats = tcp_listener_stats(addrs, nlsock)
    assert_equal 1, stats.size
    assert_equal 0, stats[addr].queued
    assert_equal 0, stats[addr].active

    @to_close << TCPSocket.new(TEST_ADDR, port)
    stats = tcp_listener_stats(addrs, nlsock)
    assert_equal 1, stats.size
    assert_equal 1, stats[addr].queued
    assert_equal 0, stats[addr].active

    @to_close << s.accept
    stats = tcp_listener_stats(addrs, nlsock)
    assert_equal 1, stats.size
    assert_equal 0, stats[addr].queued
    assert_equal 1, stats[addr].active
  ensure
    nlsock.close
  end

  def test_tcp_multi
    s1 = TCPServer.new(TEST_ADDR, 0)
    s2 = TCPServer.new(TEST_ADDR, 0)
    port1, port2 = s1.addr[1], s2.addr[1]
    addr1, addr2 = "#{TEST_ADDR}:#{port1}", "#{TEST_ADDR}:#{port2}"
    addrs = [ addr1, addr2 ]
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 0, stats[addr1].queued
    assert_equal 0, stats[addr1].active
    assert_equal 0, stats[addr2].queued
    assert_equal 0, stats[addr2].active

    @to_close << TCPSocket.new(TEST_ADDR, port1)
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 1, stats[addr1].queued
    assert_equal 0, stats[addr1].active
    assert_equal 0, stats[addr2].queued
    assert_equal 0, stats[addr2].active

    sc1 = s1.accept
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 0, stats[addr1].queued
    assert_equal 1, stats[addr1].active
    assert_equal 0, stats[addr2].queued
    assert_equal 0, stats[addr2].active

    @to_close << TCPSocket.new(TEST_ADDR, port2)
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 0, stats[addr1].queued
    assert_equal 1, stats[addr1].active
    assert_equal 1, stats[addr2].queued
    assert_equal 0, stats[addr2].active

    @to_close << TCPSocket.new(TEST_ADDR, port2)
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 0, stats[addr1].queued
    assert_equal 1, stats[addr1].active
    assert_equal 2, stats[addr2].queued
    assert_equal 0, stats[addr2].active

    @to_close << s2.accept
    stats = tcp_listener_stats(addrs)
    assert_equal 2, stats.size
    assert_equal 0, stats[addr1].queued
    assert_equal 1, stats[addr1].active
    assert_equal 1, stats[addr2].queued
    assert_equal 1, stats[addr2].active

    sc1.close
    stats = tcp_listener_stats(addrs)
    assert_equal 0, stats[addr1].queued
    assert_equal 0, stats[addr1].active
    assert_equal 1, stats[addr2].queued
    assert_equal 1, stats[addr2].active

    # make sure we don't leave "true" placeholders in results if a
    # listener becomes invalid (even momentarily).
    s2.close
    stats = tcp_listener_stats(addrs)
    assert stats.values.all? { |x| x.instance_of?(Raindrops::ListenStats) },
      "placeholders left: #{stats.inspect}"
  end

  # tries to overflow buffers
  def test_tcp_stress_test
    nr_proc = 32
    nr_sock = 500
    s = TCPServer.new(TEST_ADDR, 0)
    port = s.addr[1]
    addr = "#{TEST_ADDR}:#{port}"
    addrs = [ addr ]
    rda, wra = IO.pipe
    rdb, wrb = IO.pipe

    nr_proc.times do
      fork do
        rda.close
        wrb.close
        @to_close.concat((1..nr_sock).map { s.accept })
        wra.syswrite('.')
        wra.close
        rdb.sysread(1) # wait for parent to nuke us
      end
    end

    nr_proc.times do
      fork do
        rda.close
        wrb.close
        @to_close.concat((1..nr_sock).map { TCPSocket.new(TEST_ADDR, port) })
        wra.syswrite('.')
        wra.close
        rdb.sysread(1) # wait for parent to nuke us
      end
    end

    assert_equal('.' * (nr_proc * 2), rda.read(nr_proc * 2))

    rda.close
    stats = tcp_listener_stats(addrs)
    expect = { addr => Raindrops::ListenStats[nr_sock * nr_proc, 0] }
    assert_equal expect, stats

    @to_close << TCPSocket.new(TEST_ADDR, port)
    stats = tcp_listener_stats(addrs)
    expect = { addr => Raindrops::ListenStats[nr_sock * nr_proc, 1] }
    assert_equal expect, stats

    if ENV["BENCHMARK"].to_i != 0
      require 'benchmark'
      puts(Benchmark.measure{1000.times { tcp_listener_stats(addrs) }})
    end

    wrb.syswrite('.' * (nr_proc * 2)) # broadcast a wakeup
    statuses = Process.waitall
    statuses.each { |(_,status)| assert status.success?, status.inspect }
  end if ENV["STRESS"].to_i != 0
end if RUBY_PLATFORM =~ /linux/
