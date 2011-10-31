#-- encoding: UTF-8
require File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. .. .. .. test test_helper]))

class OverrideTest < ActiveSupport::TestCase
  def test_overrides_from_the_application_should_work
    flunk "this test should be overridden by the app"
  end
  
  def test_tests_within_the_plugin_should_still_run
    assert true, "non-overridden plugin tests should still run"
  end
end

Engines::Testing.override_tests_from_app