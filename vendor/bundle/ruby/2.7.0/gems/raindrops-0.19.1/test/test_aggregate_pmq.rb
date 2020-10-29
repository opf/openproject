require "test/unit"
require "raindrops"
pmq = begin
  Raindrops::Aggregate::PMQ
rescue LoadError => e
  warn "W: #{e} skipping #{__FILE__}"
  false
end
if RUBY_VERSION.to_f < 1.9
  pmq = false
  warn "W: skipping #{__FILE__}, only Ruby 1.9 supported for now"
end

Thread.abort_on_exception = true

class TestAggregatePMQ < Test::Unit::TestCase

  def setup
    @queue = "/test.#{rand}"
  end

  def teardown
    POSIX_MQ.unlink @queue
  end

  def test_run
    pmq = Raindrops::Aggregate::PMQ.new :queue => @queue
    thr = Thread.new { pmq.master_loop }
    agg = Aggregate.new
    (1..10).each { |i| pmq << i; agg << i }
    pmq.stop_master_loop
    assert thr.join
    assert_equal agg.count, pmq.count
    assert_equal agg.mean, pmq.mean
    assert_equal agg.std_dev, pmq.std_dev
    assert_equal agg.min, pmq.min
    assert_equal agg.max, pmq.max
    assert_equal agg.to_s, pmq.to_s
  end

  def test_multi_process
    nr_workers = 4
    nr = 100
    pmq = Raindrops::Aggregate::PMQ.new :queue => @queue
    pid = fork { pmq.master_loop }
    workers = (1..nr_workers).map {
      fork {
        (1..nr).each { |i| pmq << i }
        pmq.flush
      }
    }
    workers.each { |wpid| assert Process.waitpid2(wpid).last.success? }
    pmq.stop_master_loop
    assert Process.waitpid2(pid).last.success?
    assert_equal 400, pmq.count
    agg = Aggregate.new
    (1..nr_workers).map { (1..nr).each { |i| agg << i } }
    assert_equal agg.to_s, pmq.to_s
    assert_equal agg.mean, pmq.mean
    assert_equal agg.std_dev, pmq.std_dev
    assert_equal agg.min, pmq.min
    assert_equal agg.max, pmq.max
    assert_equal agg.to_s, pmq.to_s
  end
end if pmq
