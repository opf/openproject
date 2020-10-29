require 'test/unit'
require 'kgio'

class TestKgioSyssend < Test::Unit::TestCase
  def setup
    @host = '127.0.0.1' || ENV["TEST_HOST"]
  end

  def test_syssend
    srv = Kgio::TCPServer.new(@host, 0)
    port = srv.addr[1]
    client = TCPSocket.new(@host, port)
    acc = srv.kgio_accept
    th = Thread.new { client.readpartial(4) }
    sleep(0.05)
    assert_nil acc.kgio_syssend("HI", Socket::MSG_DONTWAIT | Socket::MSG_MORE)
    assert_nil acc.kgio_syssend("HI", Socket::MSG_DONTWAIT)
    assert_equal "HIHI", th.value

    buf = "*" * 123
    res = []
    case rv = acc.kgio_syssend(buf, Socket::MSG_DONTWAIT)
    when nil
    when String
      res << rv
    when Symbol
      res << rv
      break
    end while true
    assert_equal :wait_writable, res.last
    if res.size > 1
      assert_kind_of String, res[-2]
    else
      warn "res too small"
    end

    # blocking
    th = Thread.new { loop { acc.kgio_syssend("ZZZZ", 0) } }
    assert_nil th.join(0.1)
    th.kill
    assert th.join(10), 'thread should be killed'
  ensure
    [ srv, acc, client ].each { |io| io.close if io }
  end
end if RUBY_PLATFORM =~ /linux/ && Socket.const_defined?(:MSG_MORE)
