# -*- encoding: binary -*-

require 'test/unit'
require 'digest/sha1'
require 'unicorn'

class TeeInput < Unicorn::TeeInput
  attr_accessor :tmp, :len
end

class TestTeeInput < Test::Unit::TestCase

  def setup
    @rs = $/
    @rd, @wr = Kgio::UNIXSocket.pair
    @rd.sync = @wr.sync = true
    @start_pid = $$
  end

  def teardown
    return if $$ != @start_pid
    $/ = @rs
    @rd.close rescue nil
    @wr.close rescue nil
    begin
      Process.wait
    rescue Errno::ECHILD
      break
    end while true
  end

  def check_tempfiles
    tmp = @parser.env["rack.tempfiles"]
    assert_instance_of Array, tmp
    assert_operator tmp.size, :>=, 1
    assert_instance_of Unicorn::TmpIO, tmp[0]
  end

  def test_gets_long
    r = init_request("hello", 5 + (4096 * 4 * 3) + "#$/foo#$/".size)
    ti = TeeInput.new(@rd, r)
    status = line = nil
    pid = fork {
      @rd.close
      3.times { @wr.write("ffff" * 4096) }
      @wr.write "#$/foo#$/"
      @wr.close
    }
    @wr.close
    line = ti.gets
    assert_equal(4096 * 4 * 3 + 5 + $/.size, line.size)
    assert_equal("hello" << ("ffff" * 4096 * 3) << "#$/", line)
    line = ti.gets
    assert_equal "foo#$/", line
    assert_nil ti.gets
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_gets_short
    r = init_request("hello", 5 + "#$/foo".size)
    ti = TeeInput.new(@rd, r)
    status = line = nil
    pid = fork {
      @rd.close
      @wr.write "#$/foo"
      @wr.close
    }
    @wr.close
    line = ti.gets
    assert_equal("hello#$/", line)
    line = ti.gets
    assert_equal "foo", line
    assert_nil ti.gets
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_small_body
    r = init_request('hello')
    ti = TeeInput.new(@rd, r)
    assert_equal 0, @parser.content_length
    assert @parser.body_eof?
    assert_equal StringIO, ti.tmp.class
    assert_equal 0, ti.tmp.pos
    assert_equal 5, ti.size
    assert_equal 'hello', ti.read
    assert_equal '', ti.read
    assert_nil ti.read(4096)
    assert_equal 5, ti.size
  end

  def test_read_with_buffer
    r = init_request('hello')
    ti = TeeInput.new(@rd, r)
    buf = ''
    rv = ti.read(4, buf)
    assert_equal 'hell', rv
    assert_equal 'hell', buf
    assert_equal rv.object_id, buf.object_id
    assert_equal 'o', ti.read
    assert_equal nil, ti.read(5, buf)
    assert_equal 0, ti.rewind
    assert_equal 'hello', ti.read(5, buf)
    assert_equal 'hello', buf
  end

  def test_big_body
    r = init_request('.' * Unicorn::Const::MAX_BODY << 'a')
    ti = TeeInput.new(@rd, r)
    assert_equal 0, @parser.content_length
    assert @parser.body_eof?
    assert_kind_of File, ti.tmp
    assert_equal 0, ti.tmp.pos
    assert_equal Unicorn::Const::MAX_BODY + 1, ti.size
    check_tempfiles
  end

  def test_read_in_full_if_content_length
    a, b = 300, 3
    r = init_request('.' * b, 300)
    assert_equal 300, @parser.content_length
    ti = TeeInput.new(@rd, r)
    pid = fork {
      @wr.write('.' * 197)
      sleep 1 # still a *potential* race here that would make the test moot...
      @wr.write('.' * 100)
    }
    assert_equal a, ti.read(a).size
    _, status = Process.waitpid2(pid)
    assert status.success?
    @wr.close
  end

  def test_big_body_multi
    r = init_request('.', Unicorn::Const::MAX_BODY + 1)
    ti = TeeInput.new(@rd, r)
    assert_equal Unicorn::Const::MAX_BODY, @parser.content_length
    assert ! @parser.body_eof?
    assert_kind_of File, ti.tmp
    assert_equal 0, ti.tmp.pos
    assert_equal Unicorn::Const::MAX_BODY + 1, ti.size
    nr = Unicorn::Const::MAX_BODY / 4
    pid = fork {
      @rd.close
      nr.times { @wr.write('....') }
      @wr.close
    }
    @wr.close
    assert_equal '.', ti.read(1)
    assert_equal Unicorn::Const::MAX_BODY + 1, ti.size
    nr.times { |x|
      assert_equal '....', ti.read(4), "nr=#{x}"
      assert_equal Unicorn::Const::MAX_BODY + 1, ti.size
    }
    assert_nil ti.read(1)
    pid, status = Process.waitpid2(pid)
    assert status.success?
    check_tempfiles
  end

  def test_chunked
    @parser = Unicorn::HttpParser.new
    @parser.buf << "POST / HTTP/1.1\r\n" \
                   "Host: localhost\r\n" \
                   "Transfer-Encoding: chunked\r\n" \
                   "\r\n"
    assert @parser.parse
    assert_equal "", @parser.buf

    pid = fork {
      @rd.close
      5.times { @wr.write("5\r\nabcde\r\n") }
      @wr.write("0\r\n\r\n")
    }
    @wr.close
    ti = TeeInput.new(@rd, @parser)
    assert_nil @parser.content_length
    assert_nil ti.len
    assert ! @parser.body_eof?
    assert_equal 25, ti.size
    assert @parser.body_eof?
    assert_equal 25, ti.len
    assert_equal 0, ti.tmp.pos
    ti.rewind
    assert_equal 0, ti.tmp.pos
    assert_equal 'abcdeabcdeabcdeabcde', ti.read(20)
    assert_equal 20, ti.tmp.pos
    ti.rewind
    assert_equal 0, ti.tmp.pos
    assert_kind_of File, ti.tmp
    status = nil
    pid, status = Process.waitpid2(pid)
    assert status.success?
    check_tempfiles
  end

  def test_chunked_ping_pong
    @parser = Unicorn::HttpParser.new
    buf = @parser.buf
    buf << "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Transfer-Encoding: chunked\r\n" \
           "\r\n"
    assert @parser.parse
    assert_equal "", buf
    chunks = %w(aa bbb cccc dddd eeee)
    rd, wr = IO.pipe

    pid = fork {
      chunks.each do |chunk|
        rd.read(1) == "." and
          @wr.write("#{'%x' % [ chunk.size]}\r\n#{chunk}\r\n")
      end
      @wr.write("0\r\n\r\n")
    }
    ti = TeeInput.new(@rd, @parser)
    assert_nil @parser.content_length
    assert_nil ti.len
    assert ! @parser.body_eof?
    chunks.each do |chunk|
      wr.write('.')
      assert_equal chunk, ti.read(16384)
    end
    _, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_chunked_with_trailer
    @parser = Unicorn::HttpParser.new
    buf = @parser.buf
    buf << "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Trailer: Hello\r\n" \
           "Transfer-Encoding: chunked\r\n" \
           "\r\n"
    assert @parser.parse
    assert_equal "", buf

    pid = fork {
      @rd.close
      5.times { @wr.write("5\r\nabcde\r\n") }
      @wr.write("0\r\n")
      @wr.write("Hello: World\r\n\r\n")
    }
    @wr.close
    ti = TeeInput.new(@rd, @parser)
    assert_nil @parser.content_length
    assert_nil ti.len
    assert ! @parser.body_eof?
    assert_equal 25, ti.size
    assert_equal "World", @parser.env['HTTP_HELLO']
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_chunked_and_size_slow
    @parser = Unicorn::HttpParser.new
    buf = @parser.buf
    buf << "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Trailer: Hello\r\n" \
           "Transfer-Encoding: chunked\r\n" \
           "\r\n"
    assert @parser.parse
    assert_equal "", buf

    @wr.write("9\r\nabcde")
    ti = TeeInput.new(@rd, @parser)
    assert_nil @parser.content_length
    assert_equal "abcde", ti.read(9)
    assert ! @parser.body_eof?
    @wr.write("fghi\r\n0\r\nHello: World\r\n\r\n")
    assert_equal 9, ti.size
    assert_equal "fghi", ti.read(9)
    assert_equal nil, ti.read(9)
    assert_equal "World", @parser.env['HTTP_HELLO']
  end

  def test_gets_read_mix
    r = init_request("hello\nasdfasdf")
    ti = Unicorn::TeeInput.new(@rd, r)
    assert_equal "hello\n", ti.gets
    assert_equal "asdfasdf", ti.read(9)
    assert_nil ti.read(9)
  end

private

  def init_request(body, size = nil)
    @parser = Unicorn::HttpParser.new
    body = body.to_s.freeze
    buf = @parser.buf
    buf << "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Content-Length: #{size || body.size}\r\n" \
           "\r\n#{body}"
    assert @parser.parse
    assert_equal body, buf
    @buf = buf
    @parser
  end

end
