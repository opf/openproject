require 'test/unit'
require 'kgio'

class TestKgioSocket < Test::Unit::TestCase
  def test_socket_args
    s = Kgio::Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    assert_kind_of Socket, s
    assert_instance_of Kgio::Socket, s

    s = Kgio::Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    assert_kind_of Socket, s
    assert_instance_of Kgio::Socket, s
  end
end
