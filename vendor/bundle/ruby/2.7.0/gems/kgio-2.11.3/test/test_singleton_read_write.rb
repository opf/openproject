require 'test/unit'
$-w = true
require 'kgio'

class TestSingletonReadWrite < Test::Unit::TestCase

  def test_unix_socketpair
    a, b = UNIXSocket.pair
    Kgio.trywrite(a, "HELLO")
    buf = ""
    assert_equal "HELLO", Kgio.tryread(b, 5, buf)
    assert_equal "HELLO", buf
    assert_equal :wait_readable, Kgio.tryread(b, 5)
  end

  def test_arg_error
    assert_raises(ArgumentError) { Kgio.tryread }
    assert_raises(ArgumentError) { Kgio.tryread($stdin) }
    assert_raises(ArgumentError) { Kgio.trywrite($stdout) }
  end
end
