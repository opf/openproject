# -*- encoding: binary -*-

require './test/test_helper'
require 'tempfile'

class TestSocketHelper < Test::Unit::TestCase
  include Unicorn::SocketHelper
  attr_reader :logger
  GET_SLASH = "GET / HTTP/1.0\r\n\r\n".freeze

  def setup
    @log_tmp = Tempfile.new 'logger'
    @logger = Logger.new(@log_tmp.path)
    @test_addr = ENV['UNICORN_TEST_ADDR'] || '127.0.0.1'
    @test6_addr = ENV['UNICORN_TEST6_ADDR'] || '::1'
    GC.disable
  end

  def teardown
    GC.enable
  end

  def test_bind_listen_tcp
    port = unused_port @test_addr
    @tcp_listener_name = "#@test_addr:#{port}"
    @tcp_listener = bind_listen(@tcp_listener_name)
    assert TCPServer === @tcp_listener
    assert_equal @tcp_listener_name, sock_name(@tcp_listener)
  end

  def test_bind_listen_options
    port = unused_port @test_addr
    tcp_listener_name = "#@test_addr:#{port}"
    tmp = Tempfile.new 'unix.sock'
    unix_listener_name = tmp.path
    File.unlink(tmp.path)
    [ { :backlog => 5 }, { :sndbuf => 4096 }, { :rcvbuf => 4096 },
      { :backlog => 16, :rcvbuf => 4096, :sndbuf => 4096 }
    ].each do |opts|
      tcp_listener = bind_listen(tcp_listener_name, opts)
      assert TCPServer === tcp_listener
      tcp_listener.close
      unix_listener = bind_listen(unix_listener_name, opts)
      assert UNIXServer === unix_listener
      unix_listener.close
    end
  end

  def test_bind_listen_unix
    old_umask = File.umask(0777)
    tmp = Tempfile.new 'unix.sock'
    @unix_listener_path = tmp.path
    File.unlink(@unix_listener_path)
    @unix_listener = bind_listen(@unix_listener_path)
    assert UNIXServer === @unix_listener
    assert_equal @unix_listener_path, sock_name(@unix_listener)
    assert File.readable?(@unix_listener_path), "not readable"
    assert File.writable?(@unix_listener_path), "not writable"
    assert_equal 0777, File.umask
  ensure
    File.umask(old_umask)
  end

  def test_bind_listen_unix_umask
    old_umask = File.umask(0777)
    tmp = Tempfile.new 'unix.sock'
    @unix_listener_path = tmp.path
    File.unlink(@unix_listener_path)
    @unix_listener = bind_listen(@unix_listener_path, :umask => 077)
    assert UNIXServer === @unix_listener
    assert_equal @unix_listener_path, sock_name(@unix_listener)
    assert_equal 0140700, File.stat(@unix_listener_path).mode
    assert_equal 0777, File.umask
  ensure
    File.umask(old_umask)
  end

  def test_bind_listen_unix_idempotent
    test_bind_listen_unix
    a = bind_listen(@unix_listener)
    assert_equal a.fileno, @unix_listener.fileno
    unix_server = server_cast(@unix_listener)
    assert UNIXServer === unix_server
    a = bind_listen(unix_server)
    assert_equal a.fileno, unix_server.fileno
    assert_equal a.fileno, @unix_listener.fileno
  end

  def test_bind_listen_tcp_idempotent
    test_bind_listen_tcp
    a = bind_listen(@tcp_listener)
    assert_equal a.fileno, @tcp_listener.fileno
    tcp_server = server_cast(@tcp_listener)
    assert TCPServer === tcp_server
    a = bind_listen(tcp_server)
    assert_equal a.fileno, tcp_server.fileno
    assert_equal a.fileno, @tcp_listener.fileno
  end

  def test_bind_listen_unix_rebind
    test_bind_listen_unix
    new_listener = nil
    assert_raises(Errno::EADDRINUSE) do
      new_listener = bind_listen(@unix_listener_path)
    end

    File.unlink(@unix_listener_path)
    new_listener = bind_listen(@unix_listener_path)

    assert UNIXServer === new_listener
    assert new_listener.fileno != @unix_listener.fileno
    assert_equal sock_name(new_listener), sock_name(@unix_listener)
    assert_equal @unix_listener_path, sock_name(new_listener)
    pid = fork do
      client = server_cast(new_listener).accept
      client.syswrite('abcde')
      exit 0
    end
    s = UNIXSocket.new(@unix_listener_path)
    IO.select([s])
    assert_equal 'abcde', s.sysread(5)
    pid, status = Process.waitpid2(pid)
    assert status.success?
  end

  def test_server_cast
    test_bind_listen_unix
    test_bind_listen_tcp
    unix_listener_socket = Socket.for_fd(@unix_listener.fileno)
    assert Socket === unix_listener_socket
    @unix_server = server_cast(unix_listener_socket)
    assert_equal @unix_listener.fileno, @unix_server.fileno
    assert UNIXServer === @unix_server
    assert_equal(@unix_server.path, @unix_listener.path,
                 "##{@unix_server.path} != #{@unix_listener.path}")
    assert File.socket?(@unix_server.path)
    assert_equal @unix_listener_path, sock_name(@unix_server)

    tcp_listener_socket = Socket.for_fd(@tcp_listener.fileno)
    assert Socket === tcp_listener_socket
    @tcp_server = server_cast(tcp_listener_socket)
    assert_equal @tcp_listener.fileno, @tcp_server.fileno
    assert TCPServer === @tcp_server
    assert_equal @tcp_listener_name, sock_name(@tcp_server)
  end

  def test_sock_name
    test_server_cast
    sock_name(@unix_server)
  end

  def test_tcp_defer_accept_default
    return unless defined?(TCP_DEFER_ACCEPT)
    port = unused_port @test_addr
    name = "#@test_addr:#{port}"
    sock = bind_listen(name)
    cur = sock.getsockopt(Socket::SOL_TCP, TCP_DEFER_ACCEPT).unpack('i')[0]
    assert cur >= 1
  end

  def test_tcp_defer_accept_disable
    return unless defined?(TCP_DEFER_ACCEPT)
    port = unused_port @test_addr
    name = "#@test_addr:#{port}"
    sock = bind_listen(name, :tcp_defer_accept => false)
    cur = sock.getsockopt(Socket::SOL_TCP, TCP_DEFER_ACCEPT).unpack('i')[0]
    assert_equal 0, cur
  end

  def test_tcp_defer_accept_nr
    return unless defined?(TCP_DEFER_ACCEPT)
    port = unused_port @test_addr
    name = "#@test_addr:#{port}"
    sock = bind_listen(name, :tcp_defer_accept => 60)
    cur = sock.getsockopt(Socket::SOL_TCP, TCP_DEFER_ACCEPT).unpack('i')[0]
    assert cur > 1
  end

  def test_ipv6only
    port = begin
      unused_port "#@test6_addr"
    rescue Errno::EINVAL
      return
    end
    sock = bind_listen "[#@test6_addr]:#{port}", :ipv6only => true
    cur = sock.getsockopt(:IPPROTO_IPV6, :IPV6_V6ONLY).unpack('i')[0]
    assert_equal 1, cur
  rescue Errno::EAFNOSUPPORT
  end

  def test_reuseport
    return unless defined?(Socket::SO_REUSEPORT)
    port = unused_port @test_addr
    name = "#@test_addr:#{port}"
    sock = bind_listen(name, :reuseport => true)
    cur = sock.getsockopt(:SOL_SOCKET, :SO_REUSEPORT).int
    assert_operator cur, :>, 0
  rescue Errno::ENOPROTOOPT
    # kernel does not support SO_REUSEPORT (older Linux)
  end
end
