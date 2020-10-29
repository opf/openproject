# -*- encoding: binary -*-
require 'test/unit'
require 'io/nonblock'
require 'digest/sha1'
require 'fileutils'
$-w = true
require 'kgio'

module LibReadWriteTest
  RANDOM_BLOB = File.open("/dev/urandom") do |fp|
    nr = 31
    buf = fp.read(nr)
    # get roughly a 20MB block of random data
    (buf * (20 * 1024 * 1024 / nr)) + (buf * rand(123))
  end

  def teardown
    @rd.close if defined?(@rd) && ! @rd.closed?
    @wr.close if defined?(@wr) && ! @wr.closed?
    FileUtils.remove_entry_secure(@tmpdir) if defined?(@tmpdir)
  end

  def test_write_empty
    assert_nil @wr.kgio_write("")
  end

  def test_trywrite_empty
    assert_nil @wr.kgio_trywrite("")
  end

  def test_writev_empty
    assert_nil @wr.kgio_writev([])
  end

  def test_trywritev_empty
    assert_nil @wr.kgio_trywritev([])
  end

  def test_read_zero
    assert_equal "", @rd.kgio_read(0)
    buf = "foo"
    assert_equal buf.object_id, @rd.kgio_read(0, buf).object_id
    assert_equal "", buf
  end

  def test_read_shared
    a = "." * 0x1000
    b = a.dup
    @wr.syswrite "a"
    assert_equal "a", @rd.kgio_read(0x1000, a)
    assert_equal "a", a
    assert_equal "." * 0x1000, b
  end

  def test_read_shared_2
    a = "." * 0x1000
    b = a.dup
    @wr.syswrite "a"
    assert_equal "a", @rd.kgio_read(0x1000, b)
    assert_equal "a", b
    assert_equal "." * 0x1000, a
  end

  def test_tryread_zero
    assert_equal "", @rd.kgio_tryread(0)
    buf = "foo"
    assert_equal buf.object_id, @rd.kgio_tryread(0, buf).object_id
    assert_equal "", buf
  end

  def test_tryread_shared
    a = "." * 0x1000
    b = a.dup
    @wr.syswrite("a")
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_equal "a", @rd.kgio_tryread(0x1000, b)
    assert_equal "a", b
    assert_equal "." * 0x1000, a
  end

  def test_tryread_shared_2
    a = "." * 0x1000
    b = a.dup
    @wr.syswrite("a")
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_equal "a", @rd.kgio_tryread(0x1000, a)
    assert_equal "a", a
    assert_equal "." * 0x1000, b
  end

  def test_read_eof
    @wr.close
    assert_nil @rd.kgio_read(5)
  end

  def test_read_bang_eof
    @wr.close
    begin
      @rd.kgio_read!(5)
      assert false, "should never get here (line:#{__LINE__})"
    rescue EOFError => e
      assert_equal [], e.backtrace
    end
  end

  def test_tryread_eof
    @wr.close
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_nil @rd.kgio_tryread(5)
  end

  def test_write_closed
    @rd.close
    begin
      loop { @wr.kgio_write "HI" }
    rescue Errno::EPIPE, Errno::ECONNRESET => e
      assert_equal [], e.backtrace
      return
    end
    assert false, "should never get here (line:#{__LINE__})"
  end

  def test_trywrite_closed
    @rd.close
    begin
      loop { @wr.kgio_trywrite "HI" }
    rescue Errno::EPIPE, Errno::ECONNRESET => e
      assert_equal [], e.backtrace
      return
    end
    assert false, "should never get here (line:#{__LINE__})"
  end

  def test_writev_closed
    @rd.close
    begin
      loop { @wr.kgio_writev ["HI"] }
    rescue Errno::EPIPE, Errno::ECONNRESET => e
      assert_equal [], e.backtrace
      return
    end
    assert false, "should never get here (line:#{__LINE__})"
  end

  def test_trywritev_closed
    @rd.close
    begin
      loop { @wr.kgio_trywritev ["HI"] }
    rescue Errno::EPIPE, Errno::ECONNRESET => e
      assert_equal [], e.backtrace
      return
    end
    assert false, "should never get here (line:#{__LINE__})"
  end

  def test_trywrite_full
    buf = "\302\251" * 1024 * 1024
    buf2 = ""
    dig = Digest::SHA1.new
    t = Thread.new do
      sleep 1
      nr = 0
      begin
        dig.update(@rd.readpartial(4096, buf2))
        nr += buf2.size
      rescue EOFError
        break
      rescue => e
        warn "#{e.message} (#{e.class})"
      end while true
      dig.hexdigest
    end
    50.times do
      wr = buf
      begin
        rv = @wr.kgio_trywrite(wr)
        case rv
        when String
          wr = rv
        when :wait_readable
          assert false, "should never get here line=#{__LINE__}"
        when :wait_writable
          IO.select(nil, [ @wr ])
        else
          wr = false
        end
      end while wr
    end
    @wr.close
    t.join
    assert_equal '8ff79d8115f9fe38d18be858c66aa08a1cc27a66', t.value
  end

  def test_trywritev_full
    buf = ["\302\251" * 128] * 8 * 1024
    buf2 = ""
    dig = Digest::SHA1.new
    t = Thread.new do
      sleep 1
      nr = 0
      begin
        dig.update(@rd.readpartial(4096, buf2))
        nr += buf2.size
      rescue EOFError
        break
      rescue => e
        warn "#{e.message} (#{e.class})"
      end while true
      dig.hexdigest
    end
    50.times do
      wr = buf
      begin
        rv = @wr.kgio_trywritev(wr)
        case rv
        when Array
          wr = rv
        when :wait_readable
          assert false, "should never get here line=#{__LINE__}"
        when :wait_writable
          IO.select(nil, [ @wr ])
        else
          wr = false
        end
      end while wr
    end
    @wr.close
    t.join
    assert_equal '8ff79d8115f9fe38d18be858c66aa08a1cc27a66', t.value
  end

  def test_write_conv
    assert_equal nil, @wr.kgio_write(10)
    assert_equal "10", @rd.kgio_read(2)
  end

  def test_trywrite_conv
    assert_equal nil, @wr.kgio_trywrite(10)
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_equal "10", @rd.kgio_tryread(2)
  end

  def test_tryread_empty
    assert_equal :wait_readable, @rd.kgio_tryread(1)
  end

  def test_read_too_much
    assert_equal nil, @wr.kgio_write("hi")
    assert_equal "hi", @rd.kgio_read(4)
  end

  def test_tryread_too_much
    assert_equal nil, @wr.kgio_trywrite("hi")
    assert_equal @rd, @rd.kgio_wait_readable
    assert_equal "hi", @rd.kgio_tryread(4)
  end

  def test_read_short
    assert_equal nil, @wr.kgio_write("hi")
    assert_equal "h", @rd.kgio_read(1)
    assert_equal "i", @rd.kgio_read(1)
  end

  def test_tryread_short
    assert_equal nil, @wr.kgio_trywrite("hi")
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_equal "h", @rd.kgio_tryread(1)
    assert_equal "i", @rd.kgio_tryread(1)
  end

  def test_read_extra_buf
    tmp = ""
    tmp_object_id = tmp.object_id
    assert_equal nil, @wr.kgio_write("hi")
    rv = @rd.kgio_read(2, tmp)
    assert_equal "hi", rv
    assert_equal rv.object_id, tmp.object_id
    assert_equal tmp_object_id, rv.object_id
  end

  def test_trywrite_return_wait_writable
    tmp = []
    tmp << @wr.kgio_trywrite("HI") until tmp[-1] == :wait_writable
    assert :wait_writable === tmp[-1]
    assert(!(:wait_readable === tmp[-1]))
    assert_equal :wait_writable, tmp.pop
    assert tmp.size > 0
    penultimate = tmp.pop
    assert(penultimate == "I" || penultimate == nil)
    assert tmp.size > 0
    tmp.each { |count| assert_equal nil, count }
  end

  def test_trywritev_return_wait_writable
    tmp = []
    tmp << @wr.kgio_trywritev(["HI"]) until tmp[-1] == :wait_writable
    assert :wait_writable === tmp[-1]
    assert(!(:wait_readable === tmp[-1]))
    assert_equal :wait_writable, tmp.pop
    assert tmp.size > 0
    penultimate = tmp.pop
    assert(penultimate == ["I"] || penultimate == nil,
           "penultimate is #{penultimate.inspect}")
    assert tmp.size > 0
    tmp.each { |count| assert_equal nil, count }
  end

  def test_tryread_extra_buf_eagain_clears_buffer
    tmp = "hello world"
    rv = @rd.kgio_tryread(2, tmp)
    assert_equal :wait_readable, rv
    assert_equal "", tmp
  end

  def test_tryread_extra_buf_eof_clears_buffer
    tmp = "hello world"
    @wr.close
    IO.select([@rd]) # this seems needed on FreeBSD 9.0
    assert_nil @rd.kgio_tryread(2, tmp)
    assert_equal "", tmp
  end

  def test_monster_trywrite
    buf = RANDOM_BLOB.dup
    rv = @wr.kgio_trywrite(buf)
    assert_kind_of String, rv
    assert rv.size < buf.size
    @rd.nonblock = false
    assert_equal(buf, @rd.read(buf.size - rv.size) + rv)
  end

  def test_monster_write
    buf = RANDOM_BLOB.dup
    thr = Thread.new { @wr.kgio_write(buf) }
    @rd.nonblock = false
    readed = @rd.read(buf.size)
    thr.join
    assert_nil thr.value
    assert_equal buf, readed
  end

  def test_monster_trywritev
    buf, start = [], 0
    while start < RANDOM_BLOB.size
      s = RANDOM_BLOB[start, 1000]
      start += s.size
      buf << s
    end
    rv = @wr.kgio_trywritev(buf)
    assert_kind_of Array, rv
    rv = rv.join
    assert rv.size < RANDOM_BLOB.size
    @rd.nonblock = false
    assert_equal(RANDOM_BLOB, @rd.read(RANDOM_BLOB.size - rv.size) + rv)
  end

  def test_monster_writev
    buf, start = [], 0
    while start < RANDOM_BLOB.size
      s = RANDOM_BLOB[start, 10000]
      start += s.size
      buf << s
    end
    thr = Thread.new { @wr.kgio_writev(buf) }
    @rd.nonblock = false
    readed = @rd.read(RANDOM_BLOB.size)
    thr.join
    assert_nil thr.value
    e = (RANDOM_BLOB == readed)
    assert e
  end

  def test_monster_write_wait_writable
    @wr.instance_variable_set :@nr, 0
    def @wr.kgio_wait_writable
      @nr += 1
      IO.select(nil, [self])
    end
    buf = RANDOM_BLOB
    thr = Thread.new { @wr.kgio_write(buf) }
    Thread.pass until thr.stop?
    readed = @rd.read(buf.size)
    thr.join
    assert_nil thr.value
    assert_equal buf, readed
    assert @wr.instance_variable_get(:@nr) > 0
  end

  def test_monster_writev_wait_writable
    @wr.instance_variable_set :@nr, 0
    def @wr.kgio_wait_writable
      @nr += 1
      IO.select(nil, [self])
    end
    buf = [ RANDOM_BLOB, RANDOM_BLOB ]
    buf_size = buf.inject(0){|c, s| c + s.size}
    thr = Thread.new { @wr.kgio_writev(buf) }
    Thread.pass until thr.stop?
    readed = @rd.read(buf_size)
    thr.join
    assert_nil thr.value
    e = (buf.join == readed)
    assert e
    assert @wr.instance_variable_get(:@nr) > 0
  end

  def test_wait_readable_ruby_default
    elapsed = 0
    foo = nil
    t0 = Time.now
    thr = Thread.new { sleep 1; @wr.write "HELLO" }
    foo = @rd.kgio_read(5)
    elapsed = Time.now - t0
    assert elapsed >= 1.0, "elapsed: #{elapsed}"
    assert_equal "HELLO", foo
    thr.join
    assert_equal 5, thr.value
  end

  def test_wait_writable_ruby_default
    buf = "." * 512
    nr = 0
    begin
      nr += @wr.write_nonblock(buf)
    rescue Errno::EAGAIN
      break
    end while true
    elapsed = 0
    foo = nil
    t0 = Time.now
    thr = Thread.new { sleep 1; @rd.read(nr) }
    foo = @wr.kgio_write("HELLO")
    elapsed = Time.now - t0

    assert_nil foo
    if @wr.stat.pipe?
      assert elapsed >= 1.0, "elapsed: #{elapsed}"
    end
    assert(String === foo || foo == nil)
    assert_kind_of String, thr.value
  end

  def test_wait_readable_method
    def @rd.kgio_wait_readable
      defined?(@z) ? raise(RuntimeError, "Hello") : @z = "HI"
    end
    foo = nil
    begin
      foo = @rd.kgio_read(5)
      assert false
    rescue RuntimeError => e
      assert_equal("Hello", e.message)
    end
    assert_equal "HI", @rd.instance_variable_get(:@z)
    assert_nil foo
  end

  def test_tryread_wait_readable_method
    def @rd.kgio_wait_readable
      raise "Hello"
    end
    assert_equal :wait_readable, @rd.kgio_tryread(5)
  end

  def test_trywrite_wait_readable_method
    def @wr.kgio_wait_writable
      raise "Hello"
    end
    buf = "." * 4096
    rv = nil
    until rv == :wait_writable
      rv = @wr.kgio_trywrite(buf)
    end
    assert_equal :wait_writable, rv
  end

  def test_wait_writable_method
    def @wr.kgio_wait_writable
      defined?(@z) ? raise(RuntimeError, "Hello") : @z = "HI"
    end
    n = []
    begin
      loop { n << @wr.kgio_write("HIHIHIHIHIHI") }
      assert false
    rescue RuntimeError => e
      assert_equal("Hello", e.message)
    end
    assert n.size > 0
    assert_equal "HI", @wr.instance_variable_get(:@z)
  end
end
