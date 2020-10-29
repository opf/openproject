# -*- encoding: binary -*-
require 'test/unit'
require 'raindrops'

class TestRaindrops < Test::Unit::TestCase

  def test_raindrop_counter_max
    assert_kind_of Integer, Raindrops::MAX
    assert Raindrops::MAX > 0
    printf "Raindrops::MAX = 0x%x\n", Raindrops::MAX
  end

  def test_raindrop_size
    assert_kind_of Integer, Raindrops::SIZE
    assert Raindrops::SIZE > 0
    puts "Raindrops::SIZE = #{Raindrops::SIZE}"
  end

  def test_page_size
    assert_kind_of Integer, Raindrops::PAGE_SIZE
    assert Raindrops::PAGE_SIZE > Raindrops::SIZE
  end

  def test_size_and_capa
    rd = Raindrops.new(4)
    assert_equal 4, rd.size
    assert rd.capa >= rd.size
  end

  def test_ary
    rd = Raindrops.new(4)
    assert_equal [0, 0, 0, 0] , rd.to_ary
  end

  def test_incr_no_args
    rd = Raindrops.new(4)
    assert_equal 1, rd.incr(0)
    assert_equal [1, 0, 0, 0], rd.to_ary
  end

  def test_incr_args
    rd = Raindrops.new(4)
    assert_equal 6, rd.incr(3, 6)
    assert_equal [0, 0, 0, 6], rd.to_ary
  end

  def test_decr_args
    rd = Raindrops.new(4)
    rd[3] = 6
    assert_equal 5, rd.decr(3, 1)
    assert_equal [0, 0, 0, 5], rd.to_ary
  end

  def test_incr_shared
    rd = Raindrops.new(2)
    5.times do
      pid = fork { rd.incr(1) }
      _, status = Process.waitpid2(pid)
      assert status.success?
    end
    assert_equal [0, 5], rd.to_ary
  end

  def test_incr_decr
    rd = Raindrops.new(1)
    fork { 1000000.times { rd.incr(0) } }
    1000.times { rd.decr(0) }
    statuses = Process.waitall
    statuses.each { |pid, status| assert status.success? }
    assert_equal [999000], rd.to_ary
  end

  def test_bad_incr
    rd = Raindrops.new(1)
    assert_raises(ArgumentError) { rd.incr(-1) }
    assert_raises(ArgumentError) { rd.incr(2) }
    assert_raises(ArgumentError) { rd.incr(0xffffffff) }
  end

  def test_dup
    @rd = Raindrops.new(1)
    rd = @rd.dup
    assert_equal 1, @rd.incr(0)
    assert_equal 1, rd.incr(0)
    assert_equal 2, rd.incr(0)
    assert_equal 2, rd[0]
    assert_equal 1, @rd[0]
  end

  def test_clone
    @rd = Raindrops.new(1)
    rd = @rd.clone
    assert_equal 1, @rd.incr(0)
    assert_equal 1, rd.incr(0)
    assert_equal 2, rd.incr(0)
    assert_equal 2, rd[0]
    assert_equal 1, @rd[0]
  end

  def test_big
    expect = (1..256).map { 0 }
    rd = Raindrops.new(256)
    assert_equal expect, rd.to_ary
    assert_nothing_raised { rd[255] = 5 }
    assert_equal 5, rd[255]
    assert_nothing_raised { rd[2] = 2 }

    expect[255] = 5
    expect[2] = 2
    assert_equal expect, rd.to_ary
  end

  def test_resize
    rd = Raindrops.new(4)
    assert_equal 4, rd.size
    assert_equal rd.capa, rd.size = rd.capa
    assert_equal rd.capa, rd.to_ary.size
    assert_equal 0, rd[rd.capa - 1]
    assert_equal 1, rd.incr(rd.capa - 1)
    assert_raises(ArgumentError) { rd[rd.capa] }
  end

  def test_resize_mremap
    rd = Raindrops.new(4)
    assert_equal 4, rd.size
    old_capa = rd.capa
    rd.size = rd.capa + 1
    assert_equal old_capa * 2, rd.capa

    # mremap() is currently broken with MAP_SHARED
    # https://bugzilla.kernel.org/show_bug.cgi?id=8691
    assert_equal 0, rd[old_capa]
    assert_equal rd.capa, rd.to_ary.size
    assert_equal 0, rd[rd.capa - 1]
    assert_equal 1, rd.incr(rd.capa - 1)
    assert_raises(ArgumentError) { rd[rd.capa] }
  rescue RangeError
  end # if RUBY_PLATFORM =~ /linux/

  def test_evaporate
    rd = Raindrops.new 1
    assert_nil rd.evaporate!
    assert_raises(StandardError) { rd.evaporate! }
  end

  def test_evaporate_with_fork
    tmp = Raindrops.new 2
    pid = fork do
      tmp.incr 0
      exit(tmp.evaporate! == nil)
    end
    _, status = Process.waitpid2(pid)
    assert status.success?
    assert_equal [ 1, 0 ], tmp.to_ary
    tmp.incr 1
    assert_equal [ 1, 1 ], tmp.to_ary
    pid = fork do
      tmp.incr 1
      exit([ 1, 2 ] == tmp.to_ary)
    end
    _, status = Process.waitpid2(pid)
    assert status.success?
    assert_equal [ 1, 2 ], tmp.to_ary
  end
end
