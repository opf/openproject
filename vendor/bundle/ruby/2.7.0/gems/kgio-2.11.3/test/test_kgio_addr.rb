# -*- encoding: binary -*-
require 'test/unit'
$-w = true
require 'kgio'

class TestKgioAddr < Test::Unit::TestCase
  def test_tcp
    addr = ENV["TEST_HOST"] || '127.0.0.1'
    tcp = TCPServer.new(addr, 0)
    port = tcp.addr[1]
    client = Kgio::TCPSocket.new(addr, port)
    accepted = tcp.accept
    assert ! accepted.instance_eval { defined?(@kgio_addr) }
    accepted.extend Kgio::SocketMethods
    s = accepted.kgio_addr!
    assert_equal addr, s
    assert_equal addr, accepted.instance_variable_get(:@kgio_addr)
    client.close
  end
end
