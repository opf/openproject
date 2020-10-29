require 'test/unit'
require 'fcntl'
require 'io/nonblock'
$-w = true
require 'kgio'

class TestAcceptFlags < Test::Unit::TestCase
  def test_accept_flags
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]

    client = TCPSocket.new(@host, @port)
    accepted = @srv.kgio_accept(nil, Kgio::SOCK_NONBLOCK)
    assert_instance_of Kgio::Socket, accepted
    flags = accepted.fcntl(Fcntl::F_GETFD)
    assert_equal 0, flags & Fcntl::FD_CLOEXEC
    assert_nil client.close
    assert_nil accepted.close

    client = TCPSocket.new(@host, @port)
    accepted = @srv.kgio_accept(nil, Kgio::SOCK_CLOEXEC)
    assert_instance_of Kgio::Socket, accepted
    flags = accepted.fcntl(Fcntl::F_GETFD)
    assert_equal Fcntl::FD_CLOEXEC, flags & Fcntl::FD_CLOEXEC
    assert_nil client.close
    assert_nil accepted.close

    client = TCPSocket.new(@host, @port)
    accepted = @srv.kgio_accept(nil, Kgio::SOCK_CLOEXEC|Kgio::SOCK_NONBLOCK)
    assert_instance_of Kgio::Socket, accepted
    flags = accepted.fcntl(Fcntl::F_GETFD)
    assert_equal Fcntl::FD_CLOEXEC, flags & Fcntl::FD_CLOEXEC
    assert_nil client.close
    assert_nil accepted.close

    client = TCPSocket.new(@host, @port)
    accepted = @srv.kgio_accept(nil, Kgio::SOCK_CLOEXEC|Kgio::SOCK_NONBLOCK)
    assert_instance_of Kgio::Socket, accepted
    flags = accepted.fcntl(Fcntl::F_GETFD)
    assert_equal Fcntl::FD_CLOEXEC, flags & Fcntl::FD_CLOEXEC
    assert_nil client.close
    assert_nil accepted.close
  end
end
