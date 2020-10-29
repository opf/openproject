require './test/lib_read_write.rb'

class TestKgioPipe < Test::Unit::TestCase
  def setup
    @rd, @wr = Kgio::Pipe.new
  end

  include LibReadWriteTest
end
