require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < Test::Unit::TestCase
  fixtures :versions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Version, versions(:first)
  end
end
