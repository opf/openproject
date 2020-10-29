require 'test_helper'

module SpawnImplementationTests
  def test_spawn_simple
    pid = _spawn('true')
    assert_process_exit_ok pid
  end

  def test_spawn_with_args
    pid = _spawn('true', 'with', 'some stuff')
    assert_process_exit_ok pid
  end

  def test_spawn_with_shell
    pid = _spawn('true && exit 13')
    assert_process_exit_status pid, 13
  end

  def test_spawn_with_cmdname_and_argv0_tuple
    pid = _spawn(['true', 'not-true'], 'some', 'args', 'toooo')
    assert_process_exit_ok pid
  end

  def test_spawn_with_invalid_argv
    assert_raises ArgumentError do
      _spawn(['echo','b','c','d'])
    end
  end

  ##
  # Environ

  def test_spawn_inherit_env
    ENV['PSPAWN'] = 'parent'
    pid = _spawn('test "$PSPAWN" = "parent"')
    assert_process_exit_ok pid
  ensure
    ENV.delete('PSPAWN')
  end

  def test_spawn_clean_env
    ENV['PSPAWN'] = 'parent'
    pid = _spawn({'TEMP'=>'child'}, 'test -z "$PSPAWN" && test "$TEMP" = "child"', :unsetenv_others => true)
    assert_process_exit_ok pid
  ensure
    ENV.delete('PSPAWN')
  end

  def test_spawn_set_env
    ENV['PSPAWN'] = 'parent'
    pid = _spawn({'PSPAWN'=>'child'}, 'test "$PSPAWN" = "child"')
    assert_process_exit_ok pid
  ensure
    ENV.delete('PSPAWN')
  end

  def test_spawn_unset_env
    ENV['PSPAWN'] = 'parent'
    pid = _spawn({'PSPAWN'=>nil}, 'test -z "$PSPAWN"')
    assert_process_exit_ok pid
  ensure
    ENV.delete('PSPAWN')
  end

  ##
  # FD => :close options

  def test_sanity_of_checking_clone_with_sh
    rd, wr = IO.pipe
    pid = _spawn("exec 2>/dev/null 9<&#{rd.posix_fileno} || exit 1", rd => rd)
    assert_process_exit_status pid, 0
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_close_option_with_symbolic_standard_stream_names
    pid = _spawn('true 2>/dev/null 9<&0 || exit 1', :in => :close)
    assert_process_exit_status pid, 1

    pid = _spawn('true 2>/dev/null 9>&1 8>&2 || exit 1',
                 :out => :close, :err => :close)
    assert_process_exit_status pid, 1
  end

  def test_spawn_close_on_standard_stream_io_object
    pid = _spawn('true 2>/dev/null 9<&0 || exit 1', STDIN => :close)
    assert_process_exit_status pid, 1

    pid = _spawn('true 2>/dev/null 9>&1 8>&2 || exit 1',
                 STDOUT => :close, STDOUT => :close)
    assert_process_exit_status pid, 1
  end

  def test_spawn_close_option_with_fd_number
    rd, wr = IO.pipe
    pid = _spawn("true 2>/dev/null 9<&#{rd.posix_fileno} || exit 1", rd.posix_fileno => :close)
    assert_process_exit_status pid, 1

    assert !rd.closed?
    assert !wr.closed?
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_close_option_with_io_object
    rd, wr = IO.pipe
    pid = _spawn("true 2>/dev/null 9<&#{rd.posix_fileno} || exit 1", rd => :close)
    assert_process_exit_status pid, 1

    assert !rd.closed?
    assert !wr.closed?
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_close_invalid_fd_raises_exception
    pid = _spawn("echo", "hiya", 250 => :close)
    assert_process_exit_status pid, 127
  rescue Errno::EBADF
    # this happens on darwin only. GNU does spawn and exits 127.
  end

  def test_spawn_invalid_chdir_raises_exception
    pid = _spawn("echo", "hiya", :chdir => "/this/does/not/exist")
    # fspawn does chdir in child, so it exits with 127
    assert_process_exit_status pid, 127
  rescue Errno::ENOENT
    # pspawn and native spawn do chdir in parent, so they throw an exception
  end

  def test_spawn_closing_multiple_fds_with_array_keys
    rd, wr = IO.pipe
    pid = _spawn("true 2>/dev/null 9>&#{wr.posix_fileno} || exit 1", [rd, wr, :out] => :close)
    assert_process_exit_status pid, 1
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  ##
  # FD => FD options

  def test_spawn_redirect_fds_with_symbolic_names_and_io_objects
    rd, wr = IO.pipe
    pid = _spawn("echo", "hello world", :out => wr, rd => :close)
    wr.close
    output = rd.read
    assert_process_exit_ok pid
    assert_equal "hello world\n", output
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_redirect_fds_with_fd_numbers
    rd, wr = IO.pipe
    pid = _spawn("echo", "hello world", 1 => wr.posix_fileno, rd.posix_fileno => :close)
    wr.close
    output = rd.read
    assert_process_exit_ok pid
    assert_equal "hello world\n", output
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_redirect_invalid_fds_raises_exception
    pid = _spawn("echo", "hiya", 1 => 250)
    assert_process_exit_status pid, 127
  rescue Errno::EBADF
    # this happens on darwin only. GNU does spawn and exits 127.
  end

  def test_spawn_redirect_stderr_and_stdout_to_same_fd
    rd, wr = IO.pipe
    pid = _spawn("echo hello world 1>&2", :err => wr, :out => wr, rd => :close)
    wr.close
    output = rd.read
    assert_process_exit_ok pid
    assert_equal "hello world\n", output
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  def test_spawn_does_not_close_fd_when_redirecting
    pid = _spawn("exec 2>&1", :err => :out)
    assert_process_exit_ok pid
  end

  # Ruby 1.9 Process::spawn closes all fds by default. To keep an fd open, you
  # have to pass it explicitly as fd => fd.
  def test_explicitly_passing_an_fd_as_open
    rd, wr = IO.pipe
    pid = _spawn("exec 9>&#{wr.posix_fileno} || exit 1", wr => wr)
    assert_process_exit_ok pid
  ensure
    [rd, wr].each { |fd| fd.close rescue nil }
  end

  ##
  # FD => file options

  def test_spawn_redirect_fd_to_file_with_symbolic_name
    file = File.expand_path('../test-output', __FILE__)
    text = 'redirect_fd_to_file_with_symbolic_name'
    pid = _spawn('echo', text, :out => file)
    assert_process_exit_ok pid
    assert File.exist?(file)
    assert_equal "#{text}\n", File.read(file)
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_to_file_with_fd_number
    file = File.expand_path('../test-output', __FILE__)
    text = 'redirect_fd_to_file_with_fd_number'
    pid = _spawn('echo', text, 1 => file)
    assert_process_exit_ok pid
    assert File.exist?(file)
    assert_equal "#{text}\n", File.read(file)
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_to_file_with_io_object
    file = File.expand_path('../test-output', __FILE__)
    text = 'redirect_fd_to_file_with_io_object'
    pid = _spawn('echo', text, STDOUT => file)
    assert_process_exit_ok pid
    assert File.exist?(file)
    assert_equal "#{text}\n", File.read(file)
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_from_file_with_symbolic_name
    file = File.expand_path('../test-input', __FILE__)
    text = 'redirect_fd_from_file_with_symbolic_name'
    File.open(file, 'w') { |fd| fd.write(text) }

    pid = _spawn(%Q{test "$(cat)" = "#{text}"}, :in => file)
    assert_process_exit_ok pid
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_from_file_with_fd_number
    file = File.expand_path('../test-input', __FILE__)
    text = 'redirect_fd_from_file_with_fd_number'
    File.open(file, 'w') { |fd| fd.write(text) }

    pid = _spawn(%Q{test "$(cat)" = "#{text}"}, 0 => file)
    assert_process_exit_ok pid
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_from_file_with_io_object
    file = File.expand_path('../test-input', __FILE__)
    text = 'redirect_fd_from_file_with_io_object'
    File.open(file, 'w') { |fd| fd.write(text) }

    pid = _spawn(%Q{test "$(cat)" = "#{text}"}, STDIN => file)
    assert_process_exit_ok pid
  ensure
    File.unlink(file) rescue nil
  end

  def test_spawn_redirect_fd_to_file_with_symbolic_name_and_flags
    file = File.expand_path('../test-output', __FILE__)
    text = 'redirect_fd_to_file_with_symbolic_name'
    5.times do
        pid = _spawn('echo', text, :out => [file, 'a'])
        assert_process_exit_ok pid
    end
    assert File.exist?(file)
    assert_equal "#{text}\n" * 5, File.read(file)
  ensure
    File.unlink(file) rescue nil
  end

  ##
  # :pgroup => <pgid>

  def test_spawn_inherit_pgroup_from_parent_by_default
    pgrp = Process.getpgrp
    pid = _spawn("ruby", "-e", "exit(Process.getpgrp == #{pgrp} ? 0 : 1)")
    assert_process_exit_ok pid
  end

  def test_spawn_inherit_pgroup_from_parent_when_nil
    pgrp = Process.getpgrp
    pid = _spawn("ruby", "-e", "exit(Process.getpgrp == #{pgrp} ? 0 : 1)", :pgroup => nil)
    assert_process_exit_ok pid
  end

  def test_spawn_new_pgroup_with_true
    pid = _spawn("ruby", "-e", "exit(Process.getpgrp == $$ ? 0 : 1)", :pgroup => true)
    assert_process_exit_ok pid
  end

  def test_spawn_new_pgroup_with_zero
    pid = _spawn("ruby", "-e", "exit(Process.getpgrp == $$ ? 0 : 1)", :pgroup => 0)
    assert_process_exit_ok pid
  end

  def test_spawn_explicit_pgroup
    pgrp = Process.getpgrp
    pid = _spawn("ruby", "-e", "exit(Process.getpgrp == #{pgrp} ? 0 : 1)", :pgroup => pgrp)
    assert_process_exit_ok pid
  end

  ##
  # Exceptions

  def test_spawn_raises_exception_on_unsupported_options
    exception = nil

    assert_raises ArgumentError do
      begin
        _spawn('echo howdy', :out => '/dev/null', :oops => 'blaahh')
      rescue Exception => e
        exception = e
        raise e
      end
    end

    assert_match(/oops/, exception.message)
  end

  ##
  # Assertion Helpers

  def assert_process_exit_ok(pid)
    assert_process_exit_status pid, 0
  end

  def assert_process_exit_status(pid, status)
    assert pid.to_i > 0, "pid [#{pid}] should be > 0"
    chpid = ::Process.wait(pid)
    assert_equal chpid, pid
    assert_equal status, $?.exitstatus
  end
end

class SpawnTest < Minitest::Test
  include POSIX::Spawn

  def test_spawn_methods_exposed_at_module_level
    assert POSIX::Spawn.respond_to?(:pspawn)
    assert POSIX::Spawn.respond_to?(:_pspawn)
  end

  ##
  # Options Preprocessing

  def test_extract_process_spawn_arguments_with_options
    assert_equal [{}, [['echo', 'echo'], 'hello', 'world'], {:err => :close}],
      extract_process_spawn_arguments('echo', 'hello', 'world', :err => :close)
  end

  def test_extract_process_spawn_arguments_with_options_and_env
    options = {:err => :close}
    env = {'X' => 'Y'}
    assert_equal [env, [['echo', 'echo'], 'hello world'], options],
      extract_process_spawn_arguments(env, 'echo', 'hello world', options)
  end

  def test_extract_process_spawn_arguments_with_shell_command
    assert_equal [{}, [['/bin/sh', '/bin/sh'], '-c', 'echo hello world'], {}],
      extract_process_spawn_arguments('echo hello world')
  end

  def test_extract_process_spawn_arguments_with_special_cmdname_argv_tuple
    assert_equal [{}, [['echo', 'fuuu'], 'hello world'], {}],
      extract_process_spawn_arguments(['echo', 'fuuu'], 'hello world')
  end
end

class PosixSpawnTest < Minitest::Test
  include SpawnImplementationTests
  def _spawn(*argv)
    POSIX::Spawn.pspawn(*argv)
  end
end

class ForkSpawnTest < Minitest::Test
  include SpawnImplementationTests
  def _spawn(*argv)
    POSIX::Spawn.fspawn(*argv)
  end
end

if ::Process::respond_to?(:spawn)
  class NativeSpawnTest < Minitest::Test
    include SpawnImplementationTests
    def _spawn(*argv)
      ::Process.spawn(*argv)
    end
  end
end
