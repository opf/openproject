require 'test_helper'

class SystemTest < Minitest::Test
  include POSIX::Spawn

  def test_system
    ret = system("true")
    assert_equal true, ret
    assert_equal 0, $?.exitstatus
  end

  def test_system_nonzero
    ret = system("false")
    assert_equal false, ret
    assert_equal 1, $?.exitstatus
  end

  def test_system_nonzero_via_sh
    ret = system("exit 1")
    assert_equal false, ret
    assert_equal 1, $?.exitstatus
  end

  def test_system_failure
    ret = system("nosuch")
    assert_equal false, ret
  end
end
