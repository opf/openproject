require File.dirname(__FILE__) + '/../test_helper'

class PackagesTest < Test::Unit::TestCase
  fixtures :packages

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Packages, packages(:first)
  end
end
