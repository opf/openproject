require './test/lib_read_write'
require 'tempfile'
require 'tmpdir'

class TestUnixClientReadServerWrite < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('kgio_unix_0')
    tmp = Tempfile.new('kgio_unix_0', @tmpdir)
    @path = tmp.path
    tmp.close!
    @srv = Kgio::UNIXServer.new(@path)
    @rd = Kgio::UNIXSocket.new(@path)
    @wr = @srv.kgio_tryaccept
  end

  include LibReadWriteTest
end

