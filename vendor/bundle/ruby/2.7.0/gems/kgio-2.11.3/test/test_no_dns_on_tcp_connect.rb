require 'test/unit'
$-w = true
require 'kgio'

class TestNoDnsOnTcpConnect < Test::Unit::TestCase
  def test_connect_remote
    assert_raises(ArgumentError) { Kgio::TCPSocket.new("example.com", 666) }
  end

  def test_connect_localhost
    assert_raises(ArgumentError) { Kgio::TCPSocket.new("localhost", 666) }
  end
end
