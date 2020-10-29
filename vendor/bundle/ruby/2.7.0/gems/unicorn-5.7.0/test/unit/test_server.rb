# -*- encoding: binary -*-

# Copyright (c) 2005 Zed A. Shaw
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
#
# Additional work donated by contributors.  See git history
# for more information.

require './test/test_helper'

include Unicorn

class TestHandler

  def call(env)
    while env['rack.input'].read(4096)
    end
    [200, { 'Content-Type' => 'text/plain' }, ['hello!\n']]
  rescue Unicorn::ClientShutdown, Unicorn::HttpParserError => e
    $stderr.syswrite("#{e.class}: #{e.message} #{e.backtrace.empty?}\n")
    raise e
  end
end

class TestEarlyHintsHandler
  def call(env)
    while env['rack.input'].read(4096)
    end
    env['rack.early_hints'].call(
      "Link" => "</style.css>; rel=preload; as=style\n</script.js>; rel=preload"
    )
    [200, { 'Content-Type' => 'text/plain' }, ['hello!\n']]
  end
end

class WebServerTest < Test::Unit::TestCase

  def setup
    @valid_request = "GET / HTTP/1.1\r\nHost: www.zedshaw.com\r\nContent-Type: text/plain\r\n\r\n"
    @port = unused_port
    @tester = TestHandler.new
    redirect_test_io do
      @server = HttpServer.new(@tester, :listeners => [ "127.0.0.1:#{@port}" ] )
      @server.start
    end
  end

  def teardown
    redirect_test_io do
      wait_workers_ready("test_stderr.#$$.log", 1)
      File.truncate("test_stderr.#$$.log", 0)
      @server.stop(false)
    end
    reset_sig_handlers
  end

  def test_preload_app_config
    teardown
    tmp = Tempfile.new('test_preload_app_config')
    ObjectSpace.undefine_finalizer(tmp)
    app = lambda { ||
      tmp.sysseek(0)
      tmp.truncate(0)
      tmp.syswrite($$)
      lambda { |env| [ 200, { 'Content-Type' => 'text/plain' }, [ "#$$\n" ] ] }
    }
    redirect_test_io do
      @server = HttpServer.new(app, :listeners => [ "127.0.0.1:#@port"] )
      @server.start
    end
    results = hit(["http://localhost:#@port/"])
    worker_pid = results[0].to_i
    assert worker_pid != 0
    tmp.sysseek(0)
    loader_pid = tmp.sysread(4096).to_i
    assert loader_pid != 0
    assert_equal worker_pid, loader_pid
    teardown

    redirect_test_io do
      @server = HttpServer.new(app, :listeners => [ "127.0.0.1:#@port"],
                               :preload_app => true)
      @server.start
    end
    results = hit(["http://localhost:#@port/"])
    worker_pid = results[0].to_i
    assert worker_pid != 0
    tmp.sysseek(0)
    loader_pid = tmp.sysread(4096).to_i
    assert_equal $$, loader_pid
    assert worker_pid != loader_pid
  ensure
    tmp.close!
  end

  def test_early_hints
    teardown
    redirect_test_io do
      @server = HttpServer.new(TestEarlyHintsHandler.new,
                               :listeners => [ "127.0.0.1:#@port"],
                               :early_hints => true)
      @server.start
    end

    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")

    responses = sock.read(4096)
    assert_match %r{\AHTTP/1.[01] 103\b}, responses
    assert_match %r{^Link: </style\.css>}, responses
    assert_match %r{^Link: </script\.js>}, responses

    assert_match %r{^HTTP/1.[01] 200\b}, responses
  end

  def test_broken_app
    teardown
    app = lambda { |env| raise RuntimeError, "hello" }
    # [200, {}, []] }
    redirect_test_io do
      @server = HttpServer.new(app, :listeners => [ "127.0.0.1:#@port"] )
      @server.start
    end
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")
    assert_match %r{\AHTTP/1.[01] 500\b}, sock.sysread(4096)
    assert_nil sock.close
  end

  def test_simple_server
    results = hit(["http://localhost:#{@port}/test"])
    assert_equal 'hello!\n', results[0], "Handler didn't really run"
  end

  def test_client_shutdown_writes
    bs = 15609315 * rand
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("PUT /hello HTTP/1.1\r\n")
    sock.syswrite("Host: example.com\r\n")
    sock.syswrite("Transfer-Encoding: chunked\r\n")
    sock.syswrite("Trailer: X-Foo\r\n")
    sock.syswrite("\r\n")
    sock.syswrite("%x\r\n" % [ bs ])
    sock.syswrite("F" * bs)
    sock.syswrite("\r\n0\r\nX-")
    "Foo: bar\r\n\r\n".each_byte do |x|
      sock.syswrite x.chr
      sleep 0.05
    end
    # we wrote the entire request before shutting down, server should
    # continue to process our request and never hit EOFError on our sock
    sock.shutdown(Socket::SHUT_WR)
    buf = sock.read
    assert_equal 'hello!\n', buf.split(/\r\n\r\n/).last
    next_client = Net::HTTP.get(URI.parse("http://127.0.0.1:#@port/"))
    assert_equal 'hello!\n', next_client
    lines = File.readlines("test_stderr.#$$.log")
    assert lines.grep(/^Unicorn::ClientShutdown: /).empty?
    assert_nil sock.close
  end

  def test_client_shutdown_write_truncates
    bs = 15609315 * rand
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("PUT /hello HTTP/1.1\r\n")
    sock.syswrite("Host: example.com\r\n")
    sock.syswrite("Transfer-Encoding: chunked\r\n")
    sock.syswrite("Trailer: X-Foo\r\n")
    sock.syswrite("\r\n")
    sock.syswrite("%x\r\n" % [ bs ])
    sock.syswrite("F" * (bs / 2.0))

    # shutdown prematurely, this will force the server to abort
    # processing on us even during app dispatch
    sock.shutdown(Socket::SHUT_WR)
    IO.select([sock], nil, nil, 60) or raise "Timed out"
    buf = sock.read
    assert_equal "", buf
    next_client = Net::HTTP.get(URI.parse("http://127.0.0.1:#@port/"))
    assert_equal 'hello!\n', next_client
    lines = File.readlines("test_stderr.#$$.log")
    lines = lines.grep(/^Unicorn::ClientShutdown: bytes_read=\d+/)
    assert_equal 1, lines.size
    assert_match %r{\AUnicorn::ClientShutdown: bytes_read=\d+ true$}, lines[0]
    assert_nil sock.close
  end

  def test_client_malformed_body
    bs = 15653984
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("PUT /hello HTTP/1.1\r\n")
    sock.syswrite("Host: example.com\r\n")
    sock.syswrite("Transfer-Encoding: chunked\r\n")
    sock.syswrite("Trailer: X-Foo\r\n")
    sock.syswrite("\r\n")
    sock.syswrite("%x\r\n" % [ bs ])
    sock.syswrite("F" * bs)
    begin
      File.open("/dev/urandom", "rb") { |fp| sock.syswrite(fp.sysread(16384)) }
    rescue
    end
    assert_nil sock.close
    next_client = Net::HTTP.get(URI.parse("http://127.0.0.1:#@port/"))
    assert_equal 'hello!\n', next_client
    lines = File.readlines("test_stderr.#$$.log")
    lines = lines.grep(/^Unicorn::HttpParserError: .* true$/)
    assert_equal 1, lines.size
  end

  def do_test(string, chunk, close_after=nil, shutdown_delay=0)
    # Do not use instance variables here, because it needs to be thread safe
    socket = TCPSocket.new("127.0.0.1", @port);
    request = StringIO.new(string)
    chunks_out = 0

    while data = request.read(chunk)
      chunks_out += socket.write(data)
      socket.flush
      sleep 0.2
      if close_after and chunks_out > close_after
        socket.close
        sleep 1
      end
    end
    sleep(shutdown_delay)
    socket.write(" ") # Some platforms only raise the exception on attempted write
    socket.flush
  end

  def test_trickle_attack
    do_test(@valid_request, 3)
  end

  def test_close_client
    assert_raises IOError do
      do_test(@valid_request, 10, 20)
    end
  end

  def test_bad_client
    redirect_test_io do
      do_test("GET /test HTTP/BAD", 3)
    end
  end

  def test_logger_set
    assert_equal @server.logger, Unicorn::HttpRequest::DEFAULTS["rack.logger"]
  end

  def test_logger_changed
    tmp = Logger.new($stdout)
    @server.logger = tmp
    assert_equal tmp, Unicorn::HttpRequest::DEFAULTS["rack.logger"]
  end

  def test_bad_client_400
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\nHost: foo\rbar\r\n\r\n")
    assert_match %r{\AHTTP/1.[01] 400\b}, sock.sysread(4096)
    assert_nil sock.close
  end

  def test_http_0_9
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET /hello\r\n")
    assert_match 'hello!\n', sock.sysread(4096)
    assert_nil sock.close
  end

  def test_header_is_too_long
    redirect_test_io do
      long = "GET /test HTTP/1.1\r\n" + ("X-Big: stuff\r\n" * 15000) + "\r\n"
      assert_raises Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNABORTED, Errno::EINVAL, IOError do
        do_test(long, long.length/2, 10)
      end
    end
  end

  def test_file_streamed_request
    body = "a" * (Unicorn::Const::MAX_BODY * 2)
    long = "PUT /test HTTP/1.1\r\nContent-length: #{body.length}\r\n\r\n" + body
    do_test(long, Unicorn::Const::CHUNK_SIZE * 2 - 400)
  end

  def test_file_streamed_request_bad_body
    body = "a" * (Unicorn::Const::MAX_BODY * 2)
    long = "GET /test HTTP/1.1\r\nContent-ength: #{body.length}\r\n\r\n" + body
    assert_raises(EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,
                  Errno::EBADF) {
      do_test(long, Unicorn::Const::CHUNK_SIZE * 2 - 400)
    }
  end

  def test_listener_names
    assert_equal [ "127.0.0.1:#@port" ], Unicorn.listener_names
  end
end
