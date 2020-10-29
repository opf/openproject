# -*- encoding: binary -*-
require 'test/unit'
require 'raindrops'
require 'fcntl'
$stderr.sync = $stdout.sync = true

class TestInetDiagSocket < Test::Unit::TestCase
  def test_new
    sock = Raindrops::InetDiagSocket.new
    assert_kind_of Socket, sock
    assert_kind_of Integer, sock.fileno
    flags = sock.fcntl(Fcntl::F_GETFD)
    assert_equal Fcntl::FD_CLOEXEC, flags & Fcntl::FD_CLOEXEC
    assert_nil sock.close
  end
end if RUBY_PLATFORM =~ /linux/
