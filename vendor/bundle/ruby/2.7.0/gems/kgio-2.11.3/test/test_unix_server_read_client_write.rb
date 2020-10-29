require './test/lib_read_write'
require 'tempfile'
require 'tmpdir'

class TestUnixServerReadClientWrite < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('kgio_unix_3')
    tmp = Tempfile.new('kgio_unix_3', @tmpdir)
    @path = tmp.path
    tmp.close!
    @srv = Kgio::UNIXServer.new(@path)
    @wr = Kgio::UNIXSocket.new(@path)
    @rd = @srv.kgio_tryaccept
  end

  include LibReadWriteTest
end

