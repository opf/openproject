# -*- encoding: binary -*-

# Copyright (c) 2005 Zed A. Shaw
# You can redistribute it and/or modify it under the same terms as Ruby 1.8 or
# the GPLv2+ (GPLv3+ preferred)
#
# Additional work donated by contributors.  See git history
# for more information.

STDIN.sync = STDOUT.sync = STDERR.sync = true # buffering makes debugging hard

# FIXME: move curl-dependent tests into t/
ENV['NO_PROXY'] ||= ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'

# Some tests watch a log file or a pid file to spring up to check state
# Can't rely on inotify on non-Linux and logging to a pipe makes things
# more complicated
DEFAULT_TRIES = 1000
DEFAULT_RES = 0.2

require 'test/unit'
require 'net/http'
require 'digest/sha1'
require 'uri'
require 'stringio'
require 'pathname'
require 'tempfile'
require 'fileutils'
require 'logger'
require 'unicorn'

if ENV['DEBUG']
  require 'ruby-debug'
  Debugger.start
end

unless RUBY_VERSION < '3.1'
  warn "Unicorn was only tested against MRI up to 3.0.\n" \
       "It might not properly work with #{RUBY_VERSION}"
end

def redirect_test_io
  orig_err = STDERR.dup
  orig_out = STDOUT.dup
  new_out = File.open("test_stdout.#$$.log", "a")
  new_err = File.open("test_stderr.#$$.log", "a")
  new_out.sync = new_err.sync = true

  if tail = ENV['TAIL'] # "tail -F" if GNU, "tail -f" otherwise
    require 'shellwords'
    cmd = tail.shellsplit
    cmd << new_out.path
    cmd << new_err.path
    pid = Process.spawn(*cmd, { 1 => 2, :pgroup => true })
    sleep 0.1 # wait for tail(1) to startup
  end
  STDERR.reopen(new_err)
  STDOUT.reopen(new_out)
  STDERR.sync = STDOUT.sync = true

  at_exit do
    File.unlink(new_out.path) rescue nil
    File.unlink(new_err.path) rescue nil
  end

  begin
    yield
  ensure
    STDERR.reopen(orig_err)
    STDOUT.reopen(orig_out)
    Process.kill(:TERM, pid) if pid
  end
end

# which(1) exit codes cannot be trusted on some systems
# We use UNIX shell utilities in some tests because we don't trust
# ourselves to write Ruby 100% correctly :)
def which(bin)
  ex = ENV['PATH'].split(/:/).detect do |x|
    x << "/#{bin}"
    File.executable?(x)
  end or warn "`#{bin}' not found in PATH=#{ENV['PATH']}"
  ex
end

# Either takes a string to do a get request against, or a tuple of [URI, HTTP] where
# HTTP is some kind of Net::HTTP request object (POST, HEAD, etc.)
def hit(uris)
  results = []
  uris.each do |u|
    res = nil

    if u.kind_of? String
      u = 'http://127.0.0.1:8080/' if u == 'http://0.0.0.0:8080/'
      res = Net::HTTP.get(URI.parse(u))
    else
      url = URI.parse(u[0])
      res = Net::HTTP.new(url.host, url.port).start {|h| h.request(u[1]) }
    end

    assert res != nil, "Didn't get a response: #{u}"
    results << res
  end

  return results
end

# unused_port provides an unused port on +addr+ usable for TCP that is
# guaranteed to be unused across all unicorn builds on that system.  It
# prevents race conditions by using a lock file other unicorn builds
# will see.  This is required if you perform several builds in parallel
# with a continuous integration system or run tests in parallel via
# gmake.  This is NOT guaranteed to be race-free if you run other
# processes that bind to random ports for testing (but the window
# for a race condition is very small).  You may also set UNICORN_TEST_ADDR
# to override the default test address (127.0.0.1).
def unused_port(addr = '127.0.0.1')
  retries = 100
  base = 5000
  port = sock = nil
  begin
    begin
      port = base + rand(32768 - base)
      while port == Unicorn::Const::DEFAULT_PORT
        port = base + rand(32768 - base)
      end

      sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sock.bind(Socket.pack_sockaddr_in(port, addr))
      sock.listen(5)
    rescue Errno::EADDRINUSE, Errno::EACCES
      sock.close rescue nil
      retry if (retries -= 1) >= 0
    end

    # since we'll end up closing the random port we just got, there's a race
    # condition could allow the random port we just chose to reselect itself
    # when running tests in parallel with gmake.  Create a lock file while
    # we have the port here to ensure that does not happen .
    lock_path = "#{Dir::tmpdir}/unicorn_test.#{addr}:#{port}.lock"
    File.open(lock_path, File::WRONLY|File::CREAT|File::EXCL, 0600).close
    at_exit { File.unlink(lock_path) rescue nil }
  rescue Errno::EEXIST
    sock.close rescue nil
    retry
  end
  sock.close rescue nil
  port
end

def try_require(lib)
  begin
    require lib
    true
  rescue LoadError
    false
  end
end

# sometimes the server may not come up right away
def retry_hit(uris = [])
  tries = DEFAULT_TRIES
  begin
    hit(uris)
  rescue Errno::EINVAL, Errno::ECONNREFUSED => err
    if (tries -= 1) > 0
      sleep DEFAULT_RES
      retry
    end
    raise err
  end
end

def assert_shutdown(pid)
  wait_master_ready("test_stderr.#{pid}.log")
  Process.kill(:QUIT, pid)
  pid, status = Process.waitpid2(pid)
  assert status.success?, "exited successfully"
end

def wait_workers_ready(path, nr_workers)
  tries = DEFAULT_TRIES
  lines = []
  while (tries -= 1) > 0
    begin
      lines = File.readlines(path).grep(/worker=\d+ ready/)
      lines.size == nr_workers and return
    rescue Errno::ENOENT
    end
    sleep DEFAULT_RES
  end
  raise "#{nr_workers} workers never became ready:" \
        "\n\t#{lines.join("\n\t")}\n"
end

def wait_master_ready(master_log)
  tries = DEFAULT_TRIES
  while (tries -= 1) > 0
    begin
      File.readlines(master_log).grep(/master process ready/)[0] and return
    rescue Errno::ENOENT
    end
    sleep DEFAULT_RES
  end
  raise "master process never became ready"
end

def reexec_usr2_quit_test(pid, pid_file)
  assert File.exist?(pid_file), "pid file OK"
  assert ! File.exist?("#{pid_file}.oldbin"), "oldbin pid file"
  Process.kill(:USR2, pid)
  retry_hit(["http://#{@addr}:#{@port}/"])
  wait_for_file("#{pid_file}.oldbin")
  wait_for_file(pid_file)

  old_pid = File.read("#{pid_file}.oldbin").to_i
  new_pid = File.read(pid_file).to_i

  # kill old master process
  assert_not_equal pid, new_pid
  assert_equal pid, old_pid
  Process.kill(:QUIT, old_pid)
  retry_hit(["http://#{@addr}:#{@port}/"])
  wait_for_death(old_pid)
  assert_equal new_pid, File.read(pid_file).to_i
  retry_hit(["http://#{@addr}:#{@port}/"])
  Process.kill(:QUIT, new_pid)
end

def reexec_basic_test(pid, pid_file)
  results = retry_hit(["http://#{@addr}:#{@port}/"])
  assert_equal String, results[0].class
  Process.kill(0, pid)
  master_log = "#{@tmpdir}/test_stderr.#{pid}.log"
  wait_master_ready(master_log)
  File.truncate(master_log, 0)
  nr = 50
  kill_point = 2
  nr.times do |i|
    hit(["http://#{@addr}:#{@port}/#{i}"])
    i == kill_point and Process.kill(:HUP, pid)
  end
  wait_master_ready(master_log)
  assert File.exist?(pid_file), "pid=#{pid_file} exists"
  new_pid = File.read(pid_file).to_i
  assert_not_equal pid, new_pid
  Process.kill(0, new_pid)
  Process.kill(:QUIT, new_pid)
end

def wait_for_file(path)
  tries = DEFAULT_TRIES
  while (tries -= 1) > 0 && ! File.exist?(path)
    sleep DEFAULT_RES
  end
  assert File.exist?(path), "path=#{path} exists #{caller.inspect}"
end

def xfork(&block)
  fork do
    ObjectSpace.each_object(Tempfile) do |tmp|
      ObjectSpace.undefine_finalizer(tmp)
    end
    yield
  end
end

# can't waitpid on detached processes
def wait_for_death(pid)
  tries = DEFAULT_TRIES
  while (tries -= 1) > 0
    begin
      Process.kill(0, pid)
      begin
        Process.waitpid(pid, Process::WNOHANG)
      rescue Errno::ECHILD
      end
      sleep(DEFAULT_RES)
    rescue Errno::ESRCH
      return
    end
  end
  raise "PID:#{pid} never died!"
end

def reset_sig_handlers
  %w(WINCH QUIT INT TERM USR1 USR2 HUP TTIN TTOU CHLD).each do |sig|
    trap(sig, "DEFAULT")
  end
end
