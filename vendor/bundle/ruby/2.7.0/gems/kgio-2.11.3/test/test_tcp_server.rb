require './test/lib_server_accept'

class TestKgioTCPServer < Test::Unit::TestCase

  def setup
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
  end

  def client_connect
    TCPSocket.new(@host, @port)
  end

  include LibServerAccept
end
