require File.join(File.dirname(__FILE__), *%w[.. .. test_helper])

class OverrideTest < ActiveSupport::TestCase
  def test_overrides_from_the_application_should_work
    assert true, "overriding plugin tests from the application should work"
  end
end