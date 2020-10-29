require 'test/unit'
require 'io/nonblock'
$-w = true
require 'kgio'

class TestDefaultWait < Test::Unit::TestCase

  def test_socket_pair
    a, b = Kgio::UNIXSocket.pair
    assert_equal a, a.kgio_wait_writable
    a.syswrite('.')
    assert_equal b, b.kgio_wait_readable
  end

  def test_pipe
    a, b = Kgio::Pipe.new
    assert_equal b, b.kgio_wait_writable
    b.syswrite('.')
    assert_equal a, a.kgio_wait_readable
  end

  def test_wait_readable_timed
    a, b = Kgio::Pipe.new
    t0 = Time.now
    assert_nil a.kgio_wait_readable(1.1)
    diff = Time.now - t0
    assert_in_delta diff, 1.1, 0.2

    b.kgio_write '.'
    assert_equal a, a.kgio_wait_readable(1.1)
  end

  def test_wait_writable_timed
    a, b = Kgio::Pipe.new
    buf = "*" * 65536
    true until Symbol === b.kgio_trywrite(buf)
    t0 = Time.now
    assert_nil b.kgio_wait_writable(1.1)
    diff = Time.now - t0
    assert_in_delta diff, 1.1, 0.2

    a.kgio_read(16384)
    assert_equal b, b.kgio_wait_writable(1.1)
  end
end
