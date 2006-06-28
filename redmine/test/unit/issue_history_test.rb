require File.dirname(__FILE__) + '/../test_helper'

class IssueHistoryTest < Test::Unit::TestCase
  fixtures :issue_histories

  # Replace this with your real tests.
  def test_truth
    assert_kind_of IssueHistory, issue_histories(:first)
  end
end
