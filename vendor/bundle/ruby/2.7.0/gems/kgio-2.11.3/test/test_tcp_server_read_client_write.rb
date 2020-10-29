require './test/lib_read_write'

class TesTcpServerReadClientWrite < Test::Unit::TestCase
  def setup
    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    @port = @srv.addr[1]
    @wr = Kgio::TCPSocket.new(@host, @port)
    @rd = @srv.kgio_accept
  end

  include LibReadWriteTest
end
