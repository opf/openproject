require 'tempfile'
require 'tmpdir'
require './test/lib_server_accept'

class TestKgioUNIXServer < Test::Unit::TestCase

  def setup
    @tmpdir = Dir.mktmpdir('kgio_unix_2')
    tmp = Tempfile.new('kgio_unix_2', @tmpdir)
    @path = tmp.path
    tmp.close!
    @srv = Kgio::UNIXServer.new(@path)
    @host = '127.0.0.1'
  end

  def client_connect
    UNIXSocket.new(@path)
  end

  include LibServerAccept
end
