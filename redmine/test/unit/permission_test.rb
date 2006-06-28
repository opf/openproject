require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < Test::Unit::TestCase
  fixtures :permissions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Permission, permissions(:first)
  end
end
