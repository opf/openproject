# -*- encoding: binary -*-

# Copyright (c) 2009 Eric Wong
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
#
# Ensure we stay sane in the face of signals being sent to us

require './test/test_helper'

include Unicorn

class Dd
  def initialize(bs, count)
    @count = count
    @buf = ' ' * bs
  end

  def each(&block)
    @count.times { yield @buf }
  end
end

class SignalsTest < Test::Unit::TestCase

  def setup
    @bs = 1 * 1024 * 1024
    @count = 100
    @port = unused_port
    @sock = Tempfile.new('unicorn.sock')
    @tmp = Tempfile.new('unicorn.write')
    @tmp.sync = true
    File.unlink(@sock.path)
    File.unlink(@tmp.path)
    @server_opts = {
      :listeners => [ "127.0.0.1:#@port", @sock.path ],
      :after_fork => lambda { |server,worker|
        trap(:HUP) { @tmp.syswrite('.') }
      },
    }
    @server = nil
  end

  def teardown
    reset_sig_handlers
  end

  def test_worker_dies_on_dead_master
    pid = fork {
      app = lambda { |env| [ 200, {'X-Pid' => "#$$" }, [] ] }
      opts = @server_opts.merge(:timeout => 3)
      redirect_test_io { HttpServer.new(app, opts).start.join }
    }
    wait_workers_ready("test_stderr.#{pid}.log", 1)
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")
    buf = sock.readpartial(4096)
    assert_nil sock.close
    buf =~ /\bX-Pid: (\d+)\b/ or raise Exception
    child = $1.to_i
    wait_master_ready("test_stderr.#{pid}.log")
    wait_workers_ready("test_stderr.#{pid}.log", 1)
    Process.kill(:KILL, pid)
    Process.waitpid(pid)
    File.unlink("test_stderr.#{pid}.log", "test_stdout.#{pid}.log")
    t0 = Time.now
    assert child
    assert t0
    assert_raises(Errno::ESRCH) { loop { Process.kill(0, child); sleep 0.2 } }
    assert((Time.now - t0) < 60)
  end

  def test_sleepy_kill
    rd, wr = IO.pipe
    pid = fork {
      rd.close
      app = lambda { |env| wr.syswrite('.'); sleep; [ 200, {}, [] ] }
      redirect_test_io { HttpServer.new(app, @server_opts).start.join }
    }
    wr.close
    wait_workers_ready("test_stderr.#{pid}.log", 1)
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")
    buf = rd.readpartial(1)
    wait_master_ready("test_stderr.#{pid}.log")
    Process.kill(:INT, pid)
    Process.waitpid(pid)
    assert_equal '.', buf
    buf = nil
    assert_raises(EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,
                  Errno::EBADF) do
      buf = sock.sysread(4096)
    end
    assert_nil buf
  end

  def test_timeout_slow_response
    pid = fork {
      app = lambda { |env| sleep }
      opts = @server_opts.merge(:timeout => 3)
      redirect_test_io { HttpServer.new(app, opts).start.join }
    }
    t0 = Time.now
    wait_workers_ready("test_stderr.#{pid}.log", 1)
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")

    buf = nil
    assert_raises(EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,
                  Errno::EBADF) do
      buf = sock.sysread(4096)
    end
    diff = Time.now - t0
    assert_nil buf
    assert diff > 1.0, "diff was #{diff.inspect}"
    assert diff < 60.0
  ensure
    Process.kill(:TERM, pid) rescue nil
  end

  def test_response_write
    app = lambda { |env|
      [ 200, { 'Content-Type' => 'text/plain', 'X-Pid' => Process.pid.to_s },
        Dd.new(@bs, @count) ]
    }
    redirect_test_io { @server = HttpServer.new(app, @server_opts).start }
    wait_workers_ready("test_stderr.#{$$}.log", 1)
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")
    buf = ''
    header_len = pid = nil
    buf = sock.sysread(16384, buf)
    pid = buf[/\r\nX-Pid: (\d+)\r\n/, 1].to_i
    header_len = buf[/\A(.+?\r\n\r\n)/m, 1].size
    assert pid > 0, "pid not positive: #{pid.inspect}"
    read = buf.size
    size_before = @tmp.stat.size
    assert_raises(EOFError,Errno::ECONNRESET,Errno::EPIPE,Errno::EINVAL,
                  Errno::EBADF) do
      loop do
        3.times { Process.kill(:HUP, pid) }
        sock.sysread(16384, buf)
        read += buf.size
        3.times { Process.kill(:HUP, pid) }
      end
    end

    redirect_test_io { @server.stop(true) }
    # can't check for == since pending signals get merged
    assert size_before < @tmp.stat.size
    got = read - header_len
    expect = @bs * @count
    assert_equal(expect, got, "expect=#{expect} got=#{got}")
    assert_nil sock.close
  end

  def test_request_read
    app = lambda { |env|
      while env['rack.input'].read(4096)
      end
      [ 200, {'Content-Type'=>'text/plain', 'X-Pid'=>Process.pid.to_s}, [] ]
    }
    redirect_test_io { @server = HttpServer.new(app, @server_opts).start }

    wait_workers_ready("test_stderr.#{$$}.log", 1)
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("GET / HTTP/1.0\r\n\r\n")
    pid = sock.sysread(4096)[/\r\nX-Pid: (\d+)\r\n/, 1].to_i
    assert_nil sock.close

    assert pid > 0, "pid not positive: #{pid.inspect}"
    sock = TCPSocket.new('127.0.0.1', @port)
    sock.syswrite("PUT / HTTP/1.0\r\n")
    sock.syswrite("Content-Length: #{@bs * @count}\r\n\r\n")
    1000.times { Process.kill(:HUP, pid) }
    size_before = @tmp.stat.size
    killer = fork { loop { Process.kill(:HUP, pid); sleep(0.01) } }
    buf = ' ' * @bs
    @count.times { sock.syswrite(buf) }
    Process.kill(:KILL, killer)
    Process.waitpid2(killer)
    redirect_test_io { @server.stop(true) }
    # can't check for == since pending signals get merged
    assert size_before < @tmp.stat.size
    assert_equal pid, sock.sysread(4096)[/\r\nX-Pid: (\d+)\r\n/, 1].to_i
    assert_nil sock.close
  end
end
