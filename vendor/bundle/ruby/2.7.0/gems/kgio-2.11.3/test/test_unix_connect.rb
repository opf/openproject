require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'
require 'tempfile'
require 'tmpdir'

class SubSocket < Kgio::Socket
  attr_accessor :foo
  def kgio_wait_writable
    @foo = "waited"
  end
end

class TestKgioUnixConnect < Test::Unit::TestCase

  def setup
    @tmpdir = Dir.mktmpdir('kgio_unix_1')
    tmp = Tempfile.new('kgio_unix_1', @tmpdir)
    @path = tmp.path
    tmp.close!
    @srv = Kgio::UNIXServer.new(@path)
    @addr = Socket.pack_sockaddr_un(@path)
  end

  def teardown
    @srv.close unless @srv.closed?
    File.unlink(@path)
    FileUtils.remove_entry_secure(@tmpdir)
    Kgio.accept_cloexec = true
  end

  def test_unix_socket_new_invalid
    assert_raises(ArgumentError) { Kgio::UNIXSocket.new('*' * 1024 * 1024) }
  end

  def test_unix_socket_new
    sock = Kgio::UNIXSocket.new(@path)

    sock.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, sock.close_on_exec?)

    assert_instance_of Kgio::UNIXSocket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_new
    sock = Kgio::Socket.new(@addr)

    sock.respond_to?(:close_on_exec?) and
      assert_equal(RUBY_VERSION.to_f >= 2.0, sock.close_on_exec?)

    assert_instance_of Kgio::Socket, sock
    ready = IO.select(nil, [ sock ])
    assert_equal sock, ready[1][0]
    assert_equal nil, sock.kgio_write("HELLO")
  end

  def test_start
    sock = Kgio::Socket.start(@addr)
    assert_instance_of Kgio::Socket, sock
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
    assert_kind_of Kgio::Socket, sock
    assert_instance_of SubSocket, sock
    assert_equal nil, sock.kgio_write("HELLO")
  end
end
