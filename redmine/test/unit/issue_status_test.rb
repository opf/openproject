require File.dirname(__FILE__) + '/../test_helper'

class IssueStatusTest < Test::Unit::TestCase
  fixtures :issue_statuses

  # Replace this with your real tests.
  def test_truth
    assert_kind_of IssueStatus, issue_statuses(:first)
  end
end
