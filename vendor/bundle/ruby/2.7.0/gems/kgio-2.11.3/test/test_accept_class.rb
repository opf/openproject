require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class TestAcceptClass < Test::Unit::TestCase
  class FooSocket < Kgio::Socket
  end

  def setup
    assert_equal Kgio::Socket, Kgio.accept_class
  end

  def teardown
    Kgio.accept_class = nil
    assert_equal Kgio::Socket, Kgio.accept_class
  end

  def test_tcp_socket
    Kgio.accept_class = Kgio::TCPSocket
    assert_equal Kgio::TCPSocket, Kgio.accept_class
  end

  def test_invalid
    assert_raises(TypeError) { Kgio.accept_class = TCPSocket }
    assert_equal Kgio::Socket, Kgio.accept_class
  end

  def test_accepted_class
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
    socks = []

    Kgio.accept_class = Kgio::TCPSocket
    socks << TCPSocket.new(@host, @port)
    assert_instance_of Kgio::TCPSocket, @srv.kgio_accept
    socks << TCPSocket.new(@host, @port)
    IO.select([@srv])
    assert_instance_of Kgio::TCPSocket, @srv.kgio_tryaccept

    Kgio.accept_class = nil
    socks << TCPSocket.new(@host, @port)
    assert_instance_of Kgio::Socket, @srv.kgio_accept
    socks << TCPSocket.new(@host, @port)
    IO.select([@srv])
    assert_instance_of Kgio::Socket, @srv.kgio_tryaccept

    Kgio.accept_class = Kgio::UNIXSocket
    socks << TCPSocket.new(@host, @port)
    assert_instance_of Kgio::UNIXSocket, @srv.kgio_accept
    socks << TCPSocket.new(@host, @port)
    IO.select([@srv])
    assert_instance_of Kgio::UNIXSocket, @srv.kgio_tryaccept

    socks << TCPSocket.new(@host, @port)
    assert_instance_of FooSocket, @srv.kgio_accept(FooSocket)

    socks << TCPSocket.new(@host, @port)
    IO.select([@srv])
    assert_instance_of FooSocket, @srv.kgio_tryaccept(FooSocket)
    socks.each(&:close)
  end
end
