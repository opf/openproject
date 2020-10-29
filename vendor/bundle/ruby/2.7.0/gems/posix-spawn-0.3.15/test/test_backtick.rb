require 'test_helper'

class BacktickTest < Minitest::Test
  include POSIX::Spawn

  def test_backtick_simple
    out = `exit`
    assert_equal '', out
    assert_equal 0, $?.exitstatus
  end

  def test_backtick_output
    out = `echo 123`
    assert_equal "123\n", out
    assert_equal 0, $?.exitstatus, 0
  end

  def test_backtick_failure
    out = `nosuchcmd 2> /dev/null`
    assert_equal '', out
    assert_equal 127, $?.exitstatus
  end

  def test_backtick_redirect
    out = `nosuchcmd 2>&1`
    regex = %r{/bin/sh: (1: )?nosuchcmd: (command )?not found}
    assert regex.match(out), "Got #{out.inspect}, expected match of pattern #{regex.inspect}"
    assert_equal 127, $?.exitstatus, 127
  end

  def test_backtick_huge
    out = `yes | head -50000`
    assert_equal 100000, out.size
    assert_equal 0, $?.exitstatus
  end
end
