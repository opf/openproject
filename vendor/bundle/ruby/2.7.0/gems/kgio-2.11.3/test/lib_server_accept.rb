require 'test/unit'
require 'fcntl'
require 'io/nonblock'
require 'fileutils'
$-w = true
require 'kgio'

module LibServerAccept

  def teardown
    @srv.close unless @srv.closed?
    FileUtils.remove_entry_secure(@tmpdir) if defined?(@tmpdir)
    Kgio.accept_cloexec = true
    Kgio.accept_nonblock = false
  end

  def test_tryaccept_success
    a = client_connect
    IO.select([@srv])
    b = @srv.kgio_tryaccept
    assert_kind_of Kgio::Socket, b
    assert_equal @host, b.kgio_addr
    a.close
  end

  def test_tryaccept_flags
    a = client_connect
    IO.select([@srv])
    b = @srv.kgio_tryaccept nil, 0
    assert_kind_of Kgio::Socket, b
    assert_equal 0, b.fcntl(Fcntl::F_GETFD)
    a.close
  end

  def test_blocking_accept_flags
    a = client_connect
    IO.select([@srv])
    b = @srv.kgio_accept nil, 0
    assert_kind_of Kgio::Socket, b
    assert_equal 0, b.fcntl(Fcntl::F_GETFD)
    a.close
  end

  def test_tryaccept_fail
    assert_equal nil, @srv.kgio_tryaccept
  end

  def test_blocking_accept
    t0 = Time.now
    pid = fork { sleep 1; a = client_connect; sleep; a.close }
    b = @srv.kgio_accept
    elapsed = Time.now - t0
    assert_kind_of Kgio::Socket, b
    assert_equal @host, b.kgio_addr
    Process.kill(:KILL, pid)
    Process.waitpid(pid)
    assert elapsed >= 1, "elapsed: #{elapsed}"
  end

  def test_blocking_accept_with_nonblock_socket
    @srv.nonblock = true
    t0 = Time.now
    pid = fork { sleep 1; a = client_connect; sleep; a.close }
    b = @srv.kgio_accept
    elapsed = Time.now - t0
    assert_kind_of Kgio::Socket, b
    assert_equal @host, b.kgio_addr
    Process.kill(:KILL, pid)
    Process.waitpid(pid)
    assert elapsed >= 1, "elapsed: #{elapsed}"

    t0 = Time.now
    pid = fork { sleep 6; a = client_connect; sleep; a.close }
    b = @srv.kgio_accept
    elapsed = Time.now - t0
    assert_kind_of Kgio::Socket, b
    assert_equal @host, b.kgio_addr
    Process.kill(:KILL, pid)
    Process.waitpid(pid)
    assert elapsed >= 6, "elapsed: #{elapsed}"

    t0 = Time.now
    pid = fork { sleep 1; a = client_connect; sleep; a.close }
    b = @srv.kgio_accept
    elapsed = Time.now - t0
    assert_kind_of Kgio::Socket, b
    assert_equal @host, b.kgio_addr
    Process.kill(:KILL, pid)
    Process.waitpid(pid)
    assert elapsed >= 1, "elapsed: #{elapsed}"
  end
end
