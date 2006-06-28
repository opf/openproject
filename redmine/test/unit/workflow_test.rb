require File.dirname(__FILE__) + '/../test_helper'

class WorkflowTest < Test::Unit::TestCase
  fixtures :workflows

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Workflow, workflows(:first)
  end
end
