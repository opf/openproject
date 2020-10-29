require 'test/unit'
require 'raindrops'

class TestRaindrops < Test::Unit::TestCase

  def test_struct_new
    @rw = Raindrops::Struct.new(:r, :w)
    assert @rw.kind_of?(Class)
  end

  TMP = Raindrops::Struct.new(:r, :w)

  def test_init_basic
    tmp = TMP.new
    assert_equal 0, tmp.r
    assert_equal 1, tmp.incr_r
    assert_equal 1, tmp.r
    assert_equal({ :r => 1, :w => 0 }, tmp.to_hash)

    assert_equal 1, tmp[0]
    assert_equal 0, tmp[1]
    assert_equal [ :r, :w ], TMP::MEMBERS
  end

  def test_init
    tmp = TMP.new(5, 6)
    assert_equal({ :r => 5, :w => 6 }, tmp.to_hash)
  end

  def test_dup
    a = TMP.new(5, 6)
    b = a.dup
    assert_equal({ :r => 5, :w => 6 }, b.to_hash)
    assert_nothing_raised { 4.times { b.decr_r } }
    assert_equal({ :r => 1, :w => 6 }, b.to_hash)
    assert_equal({ :r => 5, :w => 6 }, a.to_hash)
  end

  class Foo < Raindrops::Struct.new(:a, :b, :c, :d)
    def to_ary
      @raindrops.to_ary
    end

    def hello
      "world"
    end
  end

  def test_subclass
    assert_equal [0, 0, 0, 0], Foo.new.to_ary
    assert_equal "world", Foo.new.hello
  end

end
