require 'test/unit'
$-w = true
require 'kgio'

class TestPoll < Test::Unit::TestCase
  def teardown
    [ @rd, @wr ].each { |io| io.close unless io.closed? }
  end

  def setup
    @rd, @wr = IO.pipe
  end

  def test_constants
    assert_kind_of Integer, Kgio::POLLIN
    assert_kind_of Integer, Kgio::POLLOUT
    assert_kind_of Integer, Kgio::POLLPRI
    assert_kind_of Integer, Kgio::POLLHUP
    assert_kind_of Integer, Kgio::POLLERR
    assert_kind_of Integer, Kgio::POLLNVAL
  end

  def test_poll_symbol
    set = { @rd => :wait_readable, @wr => :wait_writable }
    res = Kgio.poll(set)
    assert_equal({@wr => Kgio::POLLOUT}, res)
    assert_equal set.object_id, res.object_id
  end

  def test_poll_integer
    set = { @wr => Kgio::POLLOUT|Kgio::POLLHUP }
    res = Kgio.poll(set)
    assert_equal({@wr => Kgio::POLLOUT}, res)
    assert_equal set.object_id, res.object_id
  end

  def test_poll_timeout
    t0 = Time.now
    res = Kgio.poll({}, 10)
    diff = Time.now - t0
    assert diff >= 0.010, "diff=#{diff}"
    assert_nil res
  end

  def test_poll_close
    thr = Thread.new { sleep 0.100; @wr.close }
    t0 = Time.now
    res = Kgio.poll({@rd => Kgio::POLLIN})
    diff = Time.now - t0
    thr.join
    assert_equal([ @rd ], res.keys)
    assert diff >= 0.010, "diff=#{diff}"
  end

  def test_signal_close
    orig = trap(:USR1) { @rd.close }
    thr = Thread.new { sleep 0.100; Process.kill(:USR1, $$) }
    t0 = Time.now
    assert_raises(IOError) do
      result = Kgio.poll({@rd => Kgio::POLLIN})
      result.each_key { |io| io.read_nonblock(1) }
    end
    diff = Time.now - t0
    thr.join
    assert diff >= 0.010, "diff=#{diff}"
  ensure
    trap(:USR1, orig)
  end

  def test_poll_EINTR
    ok = false
    orig = trap(:USR1) { ok = true }
    thr = Thread.new do
      sleep 0.100
      Process.kill(:USR1, $$)
    end
    t0 = Time.now
    res = Kgio.poll({@rd => Kgio::POLLIN}, 1000)
    diff = Time.now - t0
    thr.join
    assert_nil res
    assert diff >= 1.0, "diff=#{diff}"
    assert ok
  ensure
    trap(:USR1, orig)
  end

  def test_poll_signal_torture
    usr1 = 0
    empty = 0
    nr = 100
    set = { @rd => Kgio::POLLIN }
    orig = trap(:USR1) { usr1 += 1 }
    pid = fork do
      trap(:USR1, "DEFAULT")
      sleep 0.1
      ppid = Process.ppid
      nr.times { Process.kill(:USR1, ppid); sleep 0.05 }
      @wr.syswrite('.')
      exit!(0)
    end

    empty += 1 until Kgio.poll(set.dup, 100)
    _, status = Process.waitpid2(pid)
    assert status.success?, status.inspect
    assert usr1 > 0, "usr1: #{usr1}"
  ensure
    trap(:USR1, orig)
  end unless RUBY_PLATFORM =~ /kfreebsd-gnu/
end if Kgio.respond_to?(:poll)
