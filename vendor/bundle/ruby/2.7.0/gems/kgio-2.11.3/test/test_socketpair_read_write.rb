require './test/lib_read_write.rb'

class TestKgioUNIXSocketPair < Test::Unit::TestCase
  def setup
    @rd, @wr = Kgio::UNIXSocket.pair
  end

  include LibReadWriteTest
end
