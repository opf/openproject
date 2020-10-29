require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class SubSocket < Kgio::Socket
  attr_accessor :foo
  def kgio_wait_writable
    @foo = "waited"
  end
end

class TestKgioTcpConnect < Test::Unit::TestCase

  def setup
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
    @addr = Socket.pack_sockaddr_in(@port, @host)
  end

  def teardown
    @srv.close unless @srv.closed?
    Kgio.accept_cloexec = true
    Kgio.accept_nonblock = false
  end

  def test_new
    sock = Kgio::Socket.new(@addr)
    assert_kind_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")

    sock.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, sock.close_on_exec?)
  end

  def test_start
    sock = Kgio::Socket.start(@addr)

    sock.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, sock.close_on_exec?)

    assert_kind_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_tcp_socket_new_invalid
    assert_raises(ArgumentError) { Kgio::TCPSocket.new('example.com', 80) }
    assert_raises(ArgumentError) { Kgio::TCPSocket.new('999.999.999.999', 80) }
    assert_raises(TypeError) { Kgio::TCPSocket.new("127.0.0.1", "http") }
    assert_raises(TypeError) { Kgio::TCPSocket.new('example.com', "http") }
  end

  def test_tcp_socket_new
    sock = Kgio::TCPSocket.new(@host, @port)

    sock.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, sock.close_on_exec?)

    assert_instance_of Kgio::TCPSocket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_socket_start
    sock = SubSocket.start(@addr)
    assert_nil sock.foo
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_wait_writable_set
    sock = SubSocket.new(@addr)
    assert_equal "waited", sock.foo if RUBY_PLATFORM =~ /linux/
    IO.select(nil, [sock]) if RUBY_PLATFORM !~ /linux/
    assert_equal nil, sock.kgio_write("HELLO")
  end
end
