require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class TestPipePopen < Test::Unit::TestCase
  def test_popen
    io = Kgio::Pipe.popen("sleep 1 && echo HI")
    assert_equal :wait_readable, io.kgio_tryread(2)
    sleep 1.5
    assert_equal "HI\n", io.kgio_read(3)
    assert_nil io.kgio_read(5)
  end
end
