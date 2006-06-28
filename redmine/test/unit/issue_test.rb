require File.dirname(__FILE__) + '/../test_helper'

class IssueTest < Test::Unit::TestCase
  fixtures :issues

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Issue, issues(:first)
  end
end
