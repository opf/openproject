# -*- encoding: binary -*-

require 'test/unit'
require 'digest/sha1'
require 'unicorn'

class TestStreamInput < Test::Unit::TestCase
  def setup
    @rs = $/
    @env = {}
    @rd, @wr = Kgio::UNIXSocket.pair
    @rd.sync = @wr.sync = true
    @start_pid = $$
  end

  def teardown
    return if $$ != @start_pid
    $/ = @rs
    @rd.close rescue nil
    @wr.close rescue nil
    Process.waitall
  end

  def test_read_negative
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    assert_raises(ArgumentError) { si.read(-1) }
    assert_equal 'hello', si.read
  end

  def test_read_small
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal 'hello', si.read
    assert_equal '', si.read
    assert_nil si.read(5)
    assert_nil si.gets
  end

  def test_gets_oneliner
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal 'hello', si.gets
    assert_nil si.gets
  end

  def test_gets_multiline
    r = init_request("a\nb\n\n")
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal "a\n", si.gets
    assert_equal "b\n", si.gets
    assert_equal "\n", si.gets
    assert_nil si.gets
  end

  def test_gets_empty_rs
    $/ = nil
    r = init_request("a\nb\n\n")
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal "a\nb\n\n", si.gets
    assert_nil si.gets
  end

  def test_read_with_equal_len
    r = init_request("abcde")
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal "abcde", si.read(5)
    assert_nil si.read(5)
  end

  def test_big_body_multi
    r = init_request('.', Unicorn::Const::MAX_BODY + 1)
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal Unicorn::Const::MAX_BODY, @parser.content_length
    assert ! @parser.body_eof?
    nr = Unicorn::Const::MAX_BODY / 4
    pid = fork {
      @rd.close
      nr.times { @wr.write('....') }
      @wr.close
    }
    @wr.close
    assert_equal '.', si.read(1)
    nr.times { |x|
      assert_equal '....', si.read(4), "nr=#{x}"
    }
    assert_nil si.read(1)
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_gets_long
    r = init_request("hello", 5 + (4096 * 4 * 3) + "#$/foo#$/".size)
    si = Unicorn::StreamInput.new(@rd, r)
    status = line = nil
    pid = fork {
      @rd.close
      3.times { @wr.write("ffff" * 4096) }
      @wr.write "#$/foo#$/"
      @wr.close
    }
    @wr.close
    line = si.gets
    assert_equal(4096 * 4 * 3 + 5 + $/.size, line.size)
    assert_equal("hello" << ("ffff" * 4096 * 3) << "#$/", line)
    line = si.gets
    assert_equal "foo#$/", line
    assert_nil si.gets
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_read_with_buffer
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    buf = ''
    rv = si.read(4, buf)
    assert_equal 'hell', rv
    assert_equal 'hell', buf
    assert_equal rv.object_id, buf.object_id
    assert_equal 'o', si.read
    assert_equal nil, si.read(5, buf)
  end

  def test_read_with_buffer_clobbers
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    buf = 'foo'
    assert_equal 'hello', si.read(nil, buf)
    assert_equal 'hello', buf
    assert_equal '', si.read(nil, buf)
    assert_equal '', buf
    buf = 'asdf'
    assert_nil si.read(5, buf)
    assert_equal '', buf
  end

  def test_read_zero
    r = init_request('hello')
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal '', si.read(0)
    buf = 'asdf'
    rv = si.read(0, buf)
    assert_equal rv.object_id, buf.object_id
    assert_equal '', buf
    assert_equal 'hello', si.read
    assert_nil si.read(5)
    assert_equal '', si.read(0)
    buf = 'hello'
    rv = si.read(0, buf)
    assert_equal rv.object_id, buf.object_id
    assert_equal '', rv
  end

  def test_gets_read_mix
    r = init_request("hello\nasdfasdf")
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal "hello\n", si.gets
    assert_equal "asdfasdf", si.read(9)
    assert_nil si.read(9)
  end

  def test_gets_read_mix_chunked
    r = @parser = Unicorn::HttpParser.new
    body = "6\r\nhello"
    @buf = "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Transfer-Encoding: chunked\r\n" \
           "\r\n#{body}"
    assert_equal @env, @parser.headers(@env, @buf)
    assert_equal body, @buf
    si = Unicorn::StreamInput.new(@rd, r)
    @wr.syswrite "\n\r\n"
    assert_equal "hello\n", si.gets
    @wr.syswrite "8\r\nasdfasdf\r\n"
    assert_equal"asdfasdf", si.read(9) + si.read(9)
    @wr.syswrite "0\r\n\r\n"
    assert_nil si.read(9)
  end

  def test_gets_read_mix_big
    r = init_request("hello\n#{'.' * 65536}")
    si = Unicorn::StreamInput.new(@rd, r)
    assert_equal "hello\n", si.gets
    assert_equal '.' * 16384, si.read(16384)
    assert_equal '.' * 16383, si.read(16383)
    assert_equal '.' * 16384, si.read(16384)
    assert_equal '.' * 16385, si.read(16385)
    assert_nil si.gets
  end

  def init_request(body, size = nil)
    @parser = Unicorn::HttpParser.new
    body = body.to_s.freeze
    @buf = "POST / HTTP/1.1\r\n" \
           "Host: localhost\r\n" \
           "Content-Length: #{size || body.size}\r\n" \
           "\r\n#{body}"
    assert_equal @env, @parser.headers(@env, @buf)
    assert_equal body, @buf
    @parser
  end
end
