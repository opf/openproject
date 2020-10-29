# -*- encoding: binary -*-

# Copyright (c) 2009 Eric Wong
require './test/test_helper'
require 'digest/md5'

include Unicorn

class UploadTest < Test::Unit::TestCase

  def setup
    @addr = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'
    @port = unused_port
    @hdr = {'Content-Type' => 'text/plain', 'Content-Length' => '0'}
    @bs = 4096
    @count = 256
    @server = nil

    # we want random binary data to test 1.9 encoding-aware IO craziness
    @random = File.open('/dev/urandom','rb')
    @sha1 = Digest::SHA1.new
    @sha1_app = lambda do |env|
      input = env['rack.input']
      resp = {}

      @sha1.reset
      while buf = input.read(@bs)
        @sha1.update(buf)
      end
      resp[:sha1] = @sha1.hexdigest

      # rewind and read again
      input.rewind
      @sha1.reset
      while buf = input.read(@bs)
        @sha1.update(buf)
      end

      if resp[:sha1] == @sha1.hexdigest
        resp[:sysread_read_byte_match] = true
      end

      if expect_size = env['HTTP_X_EXPECT_SIZE']
        if expect_size.to_i == input.size
          resp[:expect_size_match] = true
        end
      end
      resp[:size] = input.size
      resp[:content_md5] = env['HTTP_CONTENT_MD5']

      [ 200, @hdr.merge({'X-Resp' => resp.inspect}), [] ]
    end
  end

  def teardown
    redirect_test_io { @server.stop(false) } if @server
    @random.close
    reset_sig_handlers
  end

  def test_put
    start_server(@sha1_app)
    sock = TCPSocket.new(@addr, @port)
    sock.syswrite("PUT / HTTP/1.0\r\nContent-Length: #{length}\r\n\r\n")
    @count.times do |i|
      buf = @random.sysread(@bs)
      @sha1.update(buf)
      sock.syswrite(buf)
    end
    read = sock.read.split(/\r\n/)
    assert_equal "HTTP/1.1 200 OK", read[0]
    resp = eval(read.grep(/^X-Resp: /).first.sub!(/X-Resp: /, ''))
    assert_equal length, resp[:size]
    assert_equal @sha1.hexdigest, resp[:sha1]
  end

  def test_put_content_md5
    md5 = Digest::MD5.new
    start_server(@sha1_app)
    sock = TCPSocket.new(@addr, @port)
    sock.syswrite("PUT / HTTP/1.0\r\nTransfer-Encoding: chunked\r\n" \
                  "Trailer: Content-MD5\r\n\r\n")
    @count.times do |i|
      buf = @random.sysread(@bs)
      @sha1.update(buf)
      md5.update(buf)
      sock.syswrite("#{'%x' % buf.size}\r\n")
      sock.syswrite(buf << "\r\n")
    end
    sock.syswrite("0\r\n")

    content_md5 = [ md5.digest! ].pack('m').strip.freeze
    sock.syswrite("Content-MD5: #{content_md5}\r\n\r\n")
    read = sock.read.split(/\r\n/)
    assert_equal "HTTP/1.1 200 OK", read[0]
    resp = eval(read.grep(/^X-Resp: /).first.sub!(/X-Resp: /, ''))
    assert_equal length, resp[:size]
    assert_equal @sha1.hexdigest, resp[:sha1]
    assert_equal content_md5, resp[:content_md5]
  end

  def test_put_trickle_small
    @count, @bs = 2, 128
    start_server(@sha1_app)
    assert_equal 256, length
    sock = TCPSocket.new(@addr, @port)
    hdr = "PUT / HTTP/1.0\r\nContent-Length: #{length}\r\n\r\n"
    @count.times do
      buf = @random.sysread(@bs)
      @sha1.update(buf)
      hdr << buf
      sock.syswrite(hdr)
      hdr = ''
      sleep 0.6
    end
    read = sock.read.split(/\r\n/)
    assert_equal "HTTP/1.1 200 OK", read[0]
    resp = eval(read.grep(/^X-Resp: /).first.sub!(/X-Resp: /, ''))
    assert_equal length, resp[:size]
    assert_equal @sha1.hexdigest, resp[:sha1]
  end

  def test_put_keepalive_truncates_small_overwrite
    start_server(@sha1_app)
    sock = TCPSocket.new(@addr, @port)
    to_upload = length + 1
    sock.syswrite("PUT / HTTP/1.0\r\nContent-Length: #{to_upload}\r\n\r\n")
    @count.times do
      buf = @random.sysread(@bs)
      @sha1.update(buf)
      sock.syswrite(buf)
    end
    sock.syswrite('12345') # write 4 bytes more than we expected
    @sha1.update('1')

    buf = sock.readpartial(4096)
    while buf !~ /\r\n\r\n/
      buf << sock.readpartial(4096)
    end
    read = buf.split(/\r\n/)
    assert_equal "HTTP/1.1 200 OK", read[0]
    resp = eval(read.grep(/^X-Resp: /).first.sub!(/X-Resp: /, ''))
    assert_equal to_upload, resp[:size]
    assert_equal @sha1.hexdigest, resp[:sha1]
  end

  def test_put_excessive_overwrite_closed
    tmp = Tempfile.new('overwrite_check')
    tmp.sync = true
    start_server(lambda { |env|
      nr = 0
      while buf = env['rack.input'].read(65536)
        nr += buf.size
      end
      tmp.write(nr.to_s)
      [ 200, @hdr, [] ]
    })
    sock = TCPSocket.new(@addr, @port)
    buf = ' ' * @bs
    sock.syswrite("PUT / HTTP/1.0\r\nContent-Length: #{length}\r\n\r\n")

    @count.times { sock.syswrite(buf) }
    assert_raise(Errno::ECONNRESET, Errno::EPIPE) do
      ::Unicorn::Const::CHUNK_SIZE.times { sock.syswrite(buf) }
    end
    sock.gets
    tmp.rewind
    assert_equal length, tmp.read.to_i
  end

  # Despite reading numerous articles and inspecting the 1.9.1-p0 C
  # source, Eric Wong will never trust that we're always handling
  # encoding-aware IO objects correctly.  Thus this test uses shell
  # utilities that should always operate on files/sockets on a
  # byte-level.
  def test_uncomfortable_with_onenine_encodings
    # POSIX doesn't require all of these to be present on a system
    which('curl') or return
    which('sha1sum') or return
    which('dd') or return

    start_server(@sha1_app)

    tmp = Tempfile.new('dd_dest')
    assert(system("dd", "if=#{@random.path}", "of=#{tmp.path}",
                        "bs=#{@bs}", "count=#{@count}"),
           "dd #@random to #{tmp}")
    sha1_re = %r!\b([a-f0-9]{40})\b!
    sha1_out = `sha1sum #{tmp.path}`
    assert $?.success?, 'sha1sum ran OK'

    assert_match(sha1_re, sha1_out)
    sha1 = sha1_re.match(sha1_out)[1]
    resp = `curl -isSfN -T#{tmp.path} http://#@addr:#@port/`
    assert $?.success?, 'curl ran OK'
    assert_match(%r!\b#{sha1}\b!, resp)
    assert_match(/sysread_read_byte_match/, resp)

    # small StringIO path
    assert(system("dd", "if=#{@random.path}", "of=#{tmp.path}",
                        "bs=1024", "count=1"),
           "dd #@random to #{tmp}")
    sha1_re = %r!\b([a-f0-9]{40})\b!
    sha1_out = `sha1sum #{tmp.path}`
    assert $?.success?, 'sha1sum ran OK'

    assert_match(sha1_re, sha1_out)
    sha1 = sha1_re.match(sha1_out)[1]
    resp = `curl -isSfN -T#{tmp.path} http://#@addr:#@port/`
    assert $?.success?, 'curl ran OK'
    assert_match(%r!\b#{sha1}\b!, resp)
    assert_match(/sysread_read_byte_match/, resp)
  end

  def test_chunked_upload_via_curl
    # POSIX doesn't require all of these to be present on a system
    which('curl') or return
    which('sha1sum') or return
    which('dd') or return

    start_server(@sha1_app)

    tmp = Tempfile.new('dd_dest')
    assert(system("dd", "if=#{@random.path}", "of=#{tmp.path}",
                        "bs=#{@bs}", "count=#{@count}"),
           "dd #@random to #{tmp}")
    sha1_re = %r!\b([a-f0-9]{40})\b!
    sha1_out = `sha1sum #{tmp.path}`
    assert $?.success?, 'sha1sum ran OK'

    assert_match(sha1_re, sha1_out)
    sha1 = sha1_re.match(sha1_out)[1]
    cmd = "curl -H 'X-Expect-Size: #{tmp.size}' --tcp-nodelay \
           -isSf --no-buffer -T- " \
          "http://#@addr:#@port/"
    resp = Tempfile.new('resp')
    resp.sync = true

    rd, wr = IO.pipe.each do |io|
      io.sync = io.close_on_exec = true
    end
    pid = spawn(*cmd, { 0 => rd, 1 => resp })
    rd.close

    tmp.rewind
    @count.times { |i|
      wr.write(tmp.read(@bs))
      sleep(rand / 10) if 0 == i % 8
    }
    wr.close
    pid, status = Process.waitpid2(pid)

    resp.rewind
    resp = resp.read
    assert status.success?, 'curl ran OK'
    assert_match(%r!\b#{sha1}\b!, resp)
    assert_match(/sysread_read_byte_match/, resp)
    assert_match(/expect_size_match/, resp)
  end

  def test_curl_chunked_small
    # POSIX doesn't require all of these to be present on a system
    which('curl') or return
    which('sha1sum') or return
    which('dd') or return

    start_server(@sha1_app)

    tmp = Tempfile.new('dd_dest')
    # small StringIO path
    assert(system("dd", "if=#{@random.path}", "of=#{tmp.path}",
                        "bs=1024", "count=1"),
           "dd #@random to #{tmp}")
    sha1_re = %r!\b([a-f0-9]{40})\b!
    sha1_out = `sha1sum #{tmp.path}`
    assert $?.success?, 'sha1sum ran OK'

    assert_match(sha1_re, sha1_out)
    sha1 = sha1_re.match(sha1_out)[1]
    resp = `curl -H 'X-Expect-Size: #{tmp.size}' --tcp-nodelay \
            -isSf --no-buffer -T- http://#@addr:#@port/ < #{tmp.path}`
    assert $?.success?, 'curl ran OK'
    assert_match(%r!\b#{sha1}\b!, resp)
    assert_match(/sysread_read_byte_match/, resp)
    assert_match(/expect_size_match/, resp)
  end

  private

  def length
    @bs * @count
  end

  def start_server(app)
    redirect_test_io do
      @server = HttpServer.new(app, :listeners => [ "#{@addr}:#{@port}" ] )
      @server.start
    end
  end

end
