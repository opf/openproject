require 'test/unit'
$-w = true
require 'kgio'

class TestPeek < Test::Unit::TestCase
  class EIEIO < Errno::EIO
  end

  def teardown
    @rd.close
    @wr.close
  end

  def test_peek
    @rd, @wr = Kgio::UNIXSocket.pair
    @wr.kgio_write "HELLO"
    assert_equal "HELLO", @rd.kgio_peek(5)
    assert_equal "HELLO", @rd.kgio_trypeek(5)
    assert_equal "HELLO", @rd.kgio_read(5)
    assert_equal :wait_readable, @rd.kgio_trypeek(5)
    def @rd.kgio_wait_readable
      raise EIEIO
    end
    assert_raises(EIEIO) { @rd.kgio_peek(5) }
  end

  def test_peek_singleton
    @rd, @wr = UNIXSocket.pair
    @wr.syswrite "HELLO"
    assert_equal "HELLO", Kgio.trypeek(@rd, 666)
    assert_equal "HELLO", Kgio.trypeek(@rd, 666)
    assert_equal "HELLO", Kgio.tryread(@rd, 666)
    assert_equal :wait_readable, Kgio.trypeek(@rd, 5)
  end
end
