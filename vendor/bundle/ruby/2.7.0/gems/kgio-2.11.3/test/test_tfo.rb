require 'test/unit'
require 'kgio'

class TestTFO < Test::Unit::TestCase
  def test_constants
    if `uname -s`.chomp == "Linux" && `uname -r`.to_f >= 3.7
      assert_equal 23, Kgio::TCP_FASTOPEN
      assert_equal 0x20000000, Kgio::MSG_FASTOPEN
    end
  end

  def fastopen_ok?
    if RUBY_PLATFORM =~ /linux/
      tfo = File.read("/proc/sys/net/ipv4/tcp_fastopen").to_i
      client_enable = 1
      server_enable = 2
      enable = client_enable | server_enable
      (tfo & enable) == enable
    else
      false
    end
  end

  def test_tfo_client_server
    unless fastopen_ok?
      warn "TCP Fast Open not enabled on this system (check kernel docs)"
      return
    end
    addr = '127.0.0.1'
    qlen = 1024
    s = Kgio::TCPServer.new(addr, 0)
    s.setsockopt(:TCP, Kgio::TCP_FASTOPEN, qlen)
    port = s.local_address.ip_port
    addr = Socket.pack_sockaddr_in(port, addr)
    c = Kgio::Socket.new(:INET, :STREAM)
    assert_nil c.kgio_fastopen("HELLO", addr)
    a = s.accept
    assert_equal "HELLO", a.read(5)
    c.close
    a.close

    # ensure empty sends work
    c = Kgio::Socket.new(:INET, :STREAM)
    assert_nil c.kgio_fastopen("", addr)
    a = s.accept
    Thread.new { c.close }
    assert_nil a.read(1)
    a.close

    # try a monster packet
    buf = 'x' * (1024 * 1024 * 320)

    c = Kgio::Socket.new(:INET, :STREAM)
    thr = Thread.new do
      a = s.accept
      assert_equal buf.size, a.read(buf.size).size
      a.close
    end
    assert_nil c.kgio_fastopen(buf, addr)
    thr.join
    c.close

    # allow timeouts
    c = Kgio::Socket.new(:INET, :STREAM)
    c.setsockopt(:SOCKET, :SNDTIMEO, [ 0, 10 ].pack("l_l_"))
    unsent = c.kgio_fastopen(buf, addr)
    c.close
    assert_equal s.accept.read.size + unsent.size, buf.size
  end if defined?(Addrinfo) && defined?(Kgio::TCP_FASTOPEN)
end
