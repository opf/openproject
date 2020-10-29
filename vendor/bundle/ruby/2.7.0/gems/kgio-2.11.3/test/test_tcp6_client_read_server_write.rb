require './test/lib_read_write'

begin
  tmp = TCPServer.new(ENV["TEST_HOST6"] || '::1', 0)
  ipv6_enabled = true
  tmp.close
rescue => e
  warn "skipping IPv6 tests, host does not seem to be IPv6 enabled:"
  warn "  #{e.class}: #{e}"
  ipv6_enabled = false
end

class TestTcp6ClientReadServerWrite < Test::Unit::TestCase
  def setup
    @host = ENV["TEST_HOST6"] || '::1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
    @wr = Kgio::TCPSocket.new(@host, @port)
    @rd = @srv.kgio_accept
    assert_equal Socket.unpack_sockaddr_in(@rd.getpeername)[-1], @rd.kgio_addr
  end

  include LibReadWriteTest
end if ipv6_enabled
