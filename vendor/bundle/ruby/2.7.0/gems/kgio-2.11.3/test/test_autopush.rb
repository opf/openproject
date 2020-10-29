require 'tempfile'
require 'test/unit'
begin
  $-w = false
  RUBY_PLATFORM =~ /linux/ and require 'strace'
rescue LoadError
end
$-w = true
require 'kgio'

class TestAutopush < Test::Unit::TestCase
  TCP_CORK = 3
  TCP_NOPUSH = 4

  def setup
    Kgio.autopush = false
    assert_equal false, Kgio.autopush?

    @host = ENV["TEST_HOST"] || '127.0.0.1'
    @srv = Kgio::TCPServer.new(@host, 0)
    RUBY_PLATFORM =~ /linux/ and
      @srv.setsockopt(Socket::IPPROTO_TCP, TCP_CORK, 1)
    RUBY_PLATFORM =~ /freebsd/ and
      @srv.setsockopt(Socket::IPPROTO_TCP, TCP_NOPUSH, 1)
    @port = @srv.addr[1]
  end

  def test_autopush_accessors
    Kgio.autopush = true
    opt = RUBY_PLATFORM =~ /freebsd/ ? TCP_NOPUSH : TCP_CORK
    s = Kgio::TCPSocket.new(@host, @port)
    assert_equal 0, s.getsockopt(Socket::IPPROTO_TCP, opt).unpack('i')[0]
    assert ! s.kgio_autopush?
    s.kgio_autopush = true
    assert s.kgio_autopush?
    s.kgio_write 'asdf'
    assert_equal :wait_readable, s.kgio_tryread(1)
    assert s.kgio_autopush?
    val = s.getsockopt(Socket::IPPROTO_TCP, opt).unpack('i')[0]
    assert_operator val, :>, 0, "#{opt}=#{val} (#{RUBY_PLATFORM})"
  end

  def test_autopush_true_unix
    Kgio.autopush = true
    tmp = Tempfile.new('kgio_unix')
    @path = tmp.path
    tmp.close!
    @srv = Kgio::UNIXServer.new(@path)
    @rd = Kgio::UNIXSocket.new(@path)
    t0 = nil
    if defined?(Strace)
      io, err = Strace.me { @wr = @srv.kgio_accept }
      assert_nil err
      rc = nil
      io, err = Strace.me {
        t0 = Time.now
        @wr.kgio_write "HI\n"
        rc = @wr.kgio_tryread 666
      }
      assert_nil err
      lines = io.readlines
      assert lines.grep(/TCP_CORK/).empty?, lines.inspect
    else
      @wr = @srv.kgio_accept
      t0 = Time.now
      @wr.kgio_write "HI\n"
      rc = @wr.kgio_tryread 666
    end
    assert_equal "HI\n", @rd.kgio_read(3)
    diff = Time.now - t0
    assert(diff < 0.200, "nopush on UNIX sockets? diff=#{diff} > 200ms")
    assert_equal :wait_readable, rc
  ensure
    File.unlink(@path) rescue nil
  end

  def test_autopush_false
    Kgio.autopush = nil
    assert_equal false, Kgio.autopush?

    @wr = Kgio::TCPSocket.new(@host, @port)
    if defined?(Strace)
      io, err = Strace.me { @rd = @srv.kgio_accept }
      assert_nil err
      lines = io.readlines
      assert lines.grep(/TCP_CORK/).empty?, lines.inspect
      assert_equal 1, @rd.getsockopt(Socket::SOL_TCP, TCP_CORK).unpack("i")[0]
    else
      @rd = @srv.kgio_accept
    end

    rbuf = "..."
    t0 = Time.now
    @rd.kgio_write "HI\n"
    @wr.kgio_read(3, rbuf)
    diff = Time.now - t0
    assert(diff >= 0.190, "nopush broken? diff=#{diff} > 200ms")
    assert_equal "HI\n", rbuf
  end

  def test_autopush_true
    Kgio.autopush = true
    assert_equal true, Kgio.autopush?
    @wr = Kgio::TCPSocket.new(@host, @port)

    if defined?(Strace)
      io, err = Strace.me { @rd = @srv.kgio_accept }
      assert_nil err
      lines = io.readlines
      assert_equal 1, lines.grep(/TCP_CORK/).size, lines.inspect
      assert_equal 1, @rd.getsockopt(Socket::SOL_TCP, TCP_CORK).unpack("i")[0]
    else
      @rd = @srv.kgio_accept
    end

    @wr.write "HI\n"
    rbuf = ""
    if defined?(Strace)
      io, err = Strace.me { @rd.kgio_read(3, rbuf) }
      assert_nil err
      lines = io.readlines
      assert lines.grep(/TCP_CORK/).empty?, lines.inspect
      assert_equal "HI\n", rbuf
    else
      assert_equal "HI\n", @rd.kgio_read(3, rbuf)
    end

    t0 = Time.now
    @rd.kgio_write "HI2U2\n"
    @rd.kgio_write "HOW\n"
    rc = false

    if defined?(Strace)
      io, err = Strace.me { rc = @rd.kgio_tryread(666) }
    else
      rc = @rd.kgio_tryread(666)
    end

    @wr.readpartial(666, rbuf)
    rbuf == "HI2U2\nHOW\n" or warn "rbuf=#{rbuf.inspect} looking bad?"
    diff = Time.now - t0
    assert(diff < 0.200, "time diff=#{diff} >= 200ms")
    assert_equal :wait_readable, rc
    if defined?(Strace)
      assert_nil err
      lines = io.readlines
      assert_equal 2, lines.grep(/TCP_CORK/).size, lines.inspect
    end
    @wr.close
    @rd.close

    @wr = Kgio::TCPSocket.new(@host, @port)
    if defined?(Strace)
      io, err = Strace.me { @rd = @srv.kgio_accept }
      assert_nil err
      lines = io.readlines
      assert lines.grep(/TCP_CORK/).empty?,"optimization fail: #{lines.inspect}"
      assert_equal 1, @rd.getsockopt(Socket::SOL_TCP, TCP_CORK).unpack("i")[0]
    end
  end

  def teardown
    Kgio.autopush = false
  end
end if RUBY_PLATFORM =~ /linux|freebsd/
