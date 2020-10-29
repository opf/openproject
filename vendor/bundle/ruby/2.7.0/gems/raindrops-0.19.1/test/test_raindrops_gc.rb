# -*- encoding: binary -*-
require 'test/unit'
require 'raindrops'

class TestRaindropsGc < Test::Unit::TestCase

  # we may need to create more garbage as GC may be less aggressive
  # about expiring things.  This is completely unrealistic code,
  # though...
  def test_gc
    assert_nothing_raised do
      1000000.times { |i| Raindrops.new(24); [] }
    end
  end

  def test_gc_postfork
    tmp = Raindrops.new 2
    pid = fork do
      1000000.times do
        tmp = Raindrops.new 2
        tmp.to_ary
      end
    end
    _, status = Process.waitpid2(pid)
    assert status.success?
    assert_equal [ 0, 0 ], tmp.to_ary
    tmp.incr 1
    assert_equal [ 0, 1 ], tmp.to_ary
    pid = fork do
      tmp.incr 1
      exit([ 0, 2 ] == tmp.to_ary)
    end
    _, status = Process.waitpid2(pid)
    assert status.success?
    assert_equal [ 0, 2 ], tmp.to_ary
  end
end if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby" &&
       ENV["STRESS"].to_i != 0
