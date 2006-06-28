require File.dirname(__FILE__) + '/../test_helper'

class MemberTest < Test::Unit::TestCase
  fixtures :members

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Member, members(:first)
  end
end
