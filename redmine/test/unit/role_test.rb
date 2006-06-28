require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase
  fixtures :roles

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Role, roles(:first)
  end
end
